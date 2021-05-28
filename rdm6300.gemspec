Gem::Specification.new do |s|
  s.name        = 'rdm6300'
  s.version     = '0.1.0'
  s.add_runtime_dependency "serialport", "~> 1.3"
  s.summary     = "Read 125kHz RFID tags using the RDM6300 module"
  s.description = "rdm6300 is a  Ruby library provides a simple interface for reading 125kHz RFID tags over an RS-232 serial port using the RDM6300 module"
  s.authors     = ["Luke Stutters"]
  s.email       = 'lukestuts@gmail.com'
  s.files       = ["lib/rdm6300.rb"]
  s.homepage    =
    'https://github.com/lukestuts/ruby-rdm6300'
  s.license       = 'GPL-3.0'
end
