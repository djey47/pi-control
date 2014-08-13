# controller_focus_on_caching_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'test/unit'
require_relative 'utils/caching_helper'
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

    CachingHelper::clear_caches
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

  def test_esxi_disk_smart_should_call_gateway_first_then_cache
    # First call: cache miss
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')

    # Second call: cache hit
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    assert_false(@system_gateway.called?, 'Should use cache instead of calling system gateway')
  end

  #SlowTest!
  def test_esxi_disk_smart_with_expired_ttl_should_aways_call_gateway

    omit('Very slow test, needs to be enabled on purpose')

    # First call: cache miss
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')

    # Waits for expired TTL
    sleep(Services::CACHE_EXPIRY_SMART_SECS + 1)

    # Second call: cache miss
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_disks_smart_multi_should_call_gateway_first_then_cache
    # First call: cache miss
    get '/control/esxi/disks/1,2/smart.json'

    assert_equal(200, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')

    # Second call: cache hit
    get '/control/esxi/disks/1,2/smart.json'

    assert_equal(200, last_response.status)
    assert_false(@system_gateway.called?, 'Should use cache instead of calling system gateway')

    # Third call on single service : cache hit
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    assert_false(@system_gateway.called?, 'Should use cache instead of calling system gateway')
  end
end