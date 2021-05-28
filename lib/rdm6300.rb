require 'serialport'

##
# This class reads 125kHz tags over an RS-232 serial port using the RDM6300 module
class Rdm6300
  ##
  # Read 125kHz RFID tags from a serial port using the RDM6300 module as follows:
  # rdm = Rdm6300.new('/dev/ttyS0')
  # while true
  #   puts rdm.get_tag()
  # end
  #
  # This will return a zero-padded string with the tag number.

  # RDM6300 uses 0x02 to indicate the start of a tag
  START_CODE = 0x02
  # RDM6300 uses 0x03 to indicate the end of a tag
  END_CODE = 0x03
  # Valid tag data will always have a total length of 12 bytes over RS-232
  VALID_LENGTH = 12

  # The default serial port is /dev/ttyAMA0 since this is the primary serial port on a Raspberry Pi
  #
  # You will need to stop the Linux kernel using /dev/ttyAMA0 if you want to use it with the RDM6300
  #
  # On a Raspberry Pi 4 and Raspberry Pi OS, this can be done by adding enable_uart=1 and dtoverlay=disable-bt to /boot/config.txt
  # and removing console=serial0,115200 from /boot/cmdline.txt
  #
  # The flush delay handles the situation where rogue RF triggers the RDM6300. Genuine tag data takes less than a second
  # to transmit to the RDM6300. If there is tag data that takes longer than flush_delay to arrive, the input buffer is flushed.
  # This improves the reliability of a long-running tag reader.
  def initialize(serial_port_dev = '/dev/ttyAMA0', debug: false, flush_delay: 10)
    @serial_port_dev = serial_port_dev
    @debug = debug
    @flush_delay = flush_delay
    @serial_port = SerialPort.new(@serial_port_dev, 9600, 8, 1, SerialPort::NONE)
    @serial_port.read_timeout = 0
  end

  # Closes the serial port
  def close
    @serial_port.close
  end

  # Waits for a tag to be presented and returns a zero-padded string with the tag id
  def get_tag()
    @received_bytes = []
    @time_of_last_byte = Time.now
    @receive_started = false

    # Flush input buffer if partial data was received
    @timeout_active = true
    Thread.new do
      while @timeout_active
        sleep 1
        if @receive_started and (Time.now - @time_of_last_byte) > @flush_delay
          STDERR.puts "Received_bytes not empty after #{@flush_delay}s" if @debug
          @time_of_last_byte = Time.now
          @received_bytes = []
          @receive_started = false
        end
      end
    end

    while true
      byte = nil
      begin
        byte = @serial_port.readbyte
      rescue EOFError => e
        # This shouldn't happen if @serial_port.read_timeout == 0
        STDERR.puts "Timed out reading serial data" if @debug
        @time_of_last_byte = Time.now
        @received_bytes = []
        next
      end

      # check if this is the first byte received and it is valid. if not, reset
      if !@receive_started and byte != START_CODE
        STDERR.puts "Got initial byte but it is not #{START_CODE} (#{byte})" if @debug
        reset_serial_buffer()
      end

      if !@receive_started and byte == START_CODE
        @receive_started = true
        @time_of_last_byte = Time.now
        next
      end

      if byte > 127
        STDERR.puts "Got invalid byte #{byte}, resetting" if @debug
        reset_serial_buffer()
        next
      end

      if byte == END_CODE
        if @received_bytes.length == VALID_LENGTH
          if checksum_is_valid?(@received_bytes)
            @timeout_active = false
            return '%010d' % @received_bytes[2..9].join.to_i(16)
          else
            STDERR.puts "Failed to verify checksum for received data" if @debug
          end
        else
          STDERR.puts "Invalid number of bytes received (#{@received_bytes.length})" if @debug
        end
        reset_serial_buffer()
        next
      end

      @received_bytes << byte.chr
    end
  end

  # Resets the serial buffer, called after a tag is presented
  def reset_serial_buffer()
    @receive_started = false
    @received_bytes = []
    @serial_port.close
    @serial_port = SerialPort.new(@serial_port_dev, 9600, 8, 1, SerialPort::NONE)
    @time_of_last_byte = Time.now
  end

  # Checks if the tag checksum is valid
  def checksum_is_valid?(received_bytes)
    # Format is 10 data bytes then two checksum bytes
    # Group the received bytes into pairs, convert from ascii to hex, then XOR them
    pairs = []
    received_bytes[0..9].each_with_index do |char, index|
      next if index % 2 == 1
      pairs << char + received_bytes[index + 1]
    end
    checksum = pairs.map { |pair| pair.to_i(16) }.inject(:^)

    # Then compare to [10..12] of received_checksum
    received_checksum = (received_bytes[10] + received_bytes[11]).to_i(16)
    return checksum == received_checksum
  end
end
