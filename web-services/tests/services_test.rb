# services_test.rb - Unit Tests
ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'test/unit'
require_relative '../rupees/services'

class ServicesTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def initialize(foo)
    @system_gateway = SystemGatewayMock.new
    super(foo)
  end

  def app
    Services.new(@system_gateway)
  end

  def test_esxi_off_should_call_gateway_and_return_http_204
    @system_gateway.verify = false

    get '/control/esxi/off'

    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
    assert_equal(204, last_response.status)
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
end