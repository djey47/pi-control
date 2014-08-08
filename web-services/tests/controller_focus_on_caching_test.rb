# controller_focus_on_caching_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'test/unit'
require_relative 'utils/system_gateway_mock'
require_relative '../rupees/services'
require_relative '../rupees/controller'
require_relative '../rupees/model/virtual_machine'
require_relative '../rupees/model/schedule_status'
require_relative '../rupees/model/ssh_error'

class ControllerFocusOnCachingTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Controller.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new

    File::delete("#{Configuration::get.app_cache_directory}/#{Services::CACHE_KEY_DISKS}.cache") rescue nil
  end

  def test_esxi_disk_list_should_call_gateway_first_then_cache
    # First call: cache miss
    get '/control/esxi/disks.json'

    assert_equal(200, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')

    # Second call: cache hit
    get '/control/esxi/disks.json'

    assert_equal(200, last_response.status)
    assert_false(@system_gateway.called?, 'Should use cache instead of calling system gateway')
  end

end