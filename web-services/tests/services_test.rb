# services_test.rb - Unit Tests
ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative '../rupees/services'

class ServicesTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Services.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new
    @json_parser_opts = {:symbolize_names => true}
    @big_brother_file_name = '../logs/big_brother.log'
  end

  def test_esxi_off_should_call_gateway_and_return_http_204
    get '/control/esxi/off'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_on_should_call_gateway_and_return_http_204
    get '/control/esxi/on'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_on_should_tell_big_brother
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get '/control/esxi/on'

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(' to turn on.'))
  end

  def test_esxi_off_should_tell_big_brother
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get '/control/esxi/off'

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(' to turn off.'))
  end

  def test_big_brother_should_return_json_and_http_200
    get '/big_brother.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert(parsed_object[:events].is_a? Array)
  end

  def test_big_brother_should_tell_big_brother
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get '/big_brother.json'

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(' has just requested big brother contents.'))
  end
end

# Used for testing
class SystemGatewayMock

  attr_accessor :verify

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @verify = false
  end

  def ssh(host, user_name, command)
    raise 'Undefined host' unless not host.nil?
    raise 'Undefined user' unless not user_name.nil?
    raise "Unexpected command: #{command}" unless command == 'poweroff'
    @verify = true
  end

  def wakeonlan(mac_address, broadcast_address)
    raise 'Undefined server MAC address' unless not mac_address.nil?
    raise 'Undefined LAN broadcast address' unless not broadcast_address.nil?
    @verify = true
  end
end