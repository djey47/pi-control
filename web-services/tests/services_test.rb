# services_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative 'utils/system_gateway_mock'
require_relative '../rupees/services'
require_relative '../rupees/model/virtual_machine'
require_relative '../rupees/model/schedule_status'
require_relative '../rupees/model/ssh_error'

class ServicesTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Services.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new
    @json_parser_opts = {:symbolize_names => true}

    # Can only be deleted on first time
    File::delete(Services::BIG_BROTHER_LOG_FILE_NAME) rescue nil
  end

  def test_json_service_should_set_response_headers_when_origin_request_header_set
    get '/big_brother.json', '', Services::HDR_ORIGIN => 'http://origin'

    assert_equal('application/json;charset=utf-8', last_response.headers['Content-Type'])
    assert_equal('http://origin', last_response.headers[Services::HDR_A_C_ALLOW_ORIGIN])
  end

  def test_json_service_should_set_response_headers_when_origin_request_header_not_set
    get '/big_brother.json'

    assert_equal('application/json;charset=utf-8', last_response.headers['Content-Type'])
    assert_false(last_response.headers.has_key? Services::HDR_A_C_ALLOW_ORIGIN)
  end

  def test_esxi_off_should_call_gateway_and_return_http_204
    get '/control/esxi/off'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_off_and_esxi_unreachable_should_return_http_503
    @system_gateway.ssh_error = true

    get '/control/esxi/off'

    assert_equal(503, last_response.status)
  end

  def test_esxi_on_should_call_gateway_and_return_http_204
    get '/control/esxi/on'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_vms_should_return_json_list_and_http_200
    get '/control/esxi/vms.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_kind_of(Array, parsed_object[:virtualMachines])
    assert_equal(2, parsed_object[:virtualMachines].size, 'array size mismatch')
    vm = parsed_object[:virtualMachines][0]
    assert_equal('01', vm[:id], 'id attribute mismatch')
    assert_equal('xpenology-3810-esxi-1.1', vm[:name], 'name attribute mismatch')
    assert_equal('other26xLinux64Guest', vm[:guest_os], 'guest_os attribute mismatch')
    vm2 = parsed_object[:virtualMachines][1]
    assert_equal('02', vm2[:id], 'id attribute mismatch')
    assert_equal('xpenology-4458-gnoboot', vm2[:name], 'name attribute mismatch')
    assert_equal('other26xLinux64Guest', vm2[:guest_os], 'guest_os attribute mismatch')
  end

  def test_esxi_vms_and_esxi_unreachable_should_return_http_503
    @system_gateway.ssh_error = true

    get '/control/esxi/vms.json'

    assert_equal(503, last_response.status)
  end

  def test_esxi_vm_status_return_json_and_http_200
    get '/control/esxi/vm/1/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('ON', parsed_object[:status])
  end

  def test_esxi_vm_status_and_esxi_unreachable_return_http_503
    @system_gateway.ssh_error = true

    get '/control/esxi/vm/1/status.json'

    assert_equal(503, last_response.status)
  end

  def test_esxi_vm_status_invalid_vm_return_http_404
    get '/control/esxi/vm/0/status.json'

    assert_equal(404, last_response.status)
  end

  def test_esxi_vm_status_script_injection_return_http_400
    get '/control/esxi/vm/&%20cat%20toto.txt/status.json'

    assert_equal(400, last_response.status)
  end

  def test_esxi_schedule_enable_shoud_call_gateway_and_return_http_204
    get '/control/esxi/schedule/enable/07:00/02:00'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_schedule_enable_hour_base_10_shoud_return_http_204
    get '/control/esxi/schedule/enable/08:08/09:09'

    assert_equal(204, last_response.status)
  end

  def test_esxi_schedule_wrong_time_return_http_400
    get '/control/esxi/schedule/enable/aaaa/02:00'

    assert_equal(400, last_response.status)
  end

  def test_esxi_schedule_disable_shoud_call_gateway_and_return_http_204
    get '/control/esxi/schedule/disable'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_schedule_status_should_return_json_and_http_200
    get '/control/esxi/schedule/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('07:00', parsed_object[:status][:on_at])
    assert_equal('02:00', parsed_object[:status][:off_at])
  end

  def test_esxi_schedule_status_and_disabled_should_return_json_and_http_200
    @system_gateway.scheduling_stopped = true

    get '/control/esxi/schedule/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal(ScheduleStatus::DISABLED, parsed_object[:status])
  end

  def test_esxi_disk_list_should_return_json_and_http_200
    get '/control/esxi/disks.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert(parsed_object[:disks].is_a? Array)
    #TODO : Assert contents
  end
end