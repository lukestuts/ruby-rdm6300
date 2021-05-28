# rdm6300

Ruby gem for using the RDM6300 125kHz RFID module.

Read 125kHz RFID tags from a serial port using the RDM6300 module as follows:
```ruby
rdm = Rdm6300.new('/dev/ttyS0')
while true
  puts rdm.get_tag()
end
```

This will return a zero-padded string with the tag number.