require 'minitest/autorun'
require_relative '../lib/rdm6300'
require 'pry'

describe "Rdm6300" do
  before do
    # This lets me run tests on my mac
    serial_port = File.exist?('/dev/ttys0') ? '/dev/ttys0' : '/dev/ttyS0'
    @rdm = Rdm6300.new(serial_port)
  end

  after do
    @rdm.close
  end

  it 'rejects an invalid checksum' do
    @rdm.checksum_is_valid?(['a'] * 10 + ['0', '0']).must_equal false
  end

  it 'accepts an valid checksum' do
    @rdm.checksum_is_valid?(['0'] * 12).must_equal true
  end
end

class Rdm6300Test < Minitest::Test
=begin
  def test_english_hello
    assert_equal "hello world",
      Hola.hi("english")
  end

  def test_any_hello
    assert_equal "hello world",
      Hola.hi("ruby")
  end

  def test_spanish_hello
    assert_equal "hola mundo",
      Hola.hi("spanish")
  end
=end
end
