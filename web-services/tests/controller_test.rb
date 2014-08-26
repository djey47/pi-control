# controller_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative 'utils/caching_helper'
require_relative 'utils/system_gateway_mock'
require_relative '../rupees/services'
require_relative '../rupees/controller'
require_relative '../rupees/model/virtual_machine'
require_relative '../rupees/model/schedule_status'
require_relative '../rupees/model/ssh_error'

class ControllerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Controller.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new
    @json_parser_opts = {:symbolize_names => true}

    # Clears caches to disable feature
    CachingHelper::clear_caches
  end

  def test_json_service_should_set_response_headers_when_origin_request_header_set
    get '/big_brother.json', '', Controller::HDR_ORIGIN => 'http://origin'

    assert_equal('application/json;charset=utf-8', last_response.headers['Content-Type'])
    assert_equal('http://origin', last_response.headers[Controller::HDR_A_C_ALLOW_ORIGIN])
  end

  def test_json_service_should_set_response_headers_when_origin_request_header_not_set
    get '/big_brother.json'

    assert_equal('application/json;charset=utf-8', last_response.headers['Content-Type'])
    assert_false(last_response.headers.has_key? Controller::HDR_A_C_ALLOW_ORIGIN)
  end

  def test_esxi_off_should_call_gateway_and_return_http_204
    get '/control/esxi/off'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_off_and_esxi_unreachable_should_return_http_503
    @system_gateway.ssh_error = true

    get '/control/esxi/off'

    assert_equal(503, last_response.status)
  end

  def test_esxi_on_should_call_gateway_and_return_http_204
    get '/control/esxi/on'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_vms_should_return_json_list_and_http_200
    get '/control/esxi/vms.json'

    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
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
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
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

  def test_esxi_vm_on_should_call_gateway_and_return_http_204
    get '/control/esxi/vm/1/on'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_vm_on_invalid_vm_return_http_404
    get '/control/esxi/vm/0/on'

    assert_equal(404, last_response.status)
  end

  def test_esxi_vm_off_should_call_gateway_and_return_http_204
    get '/control/esxi/vm/1/off'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_vm_off_invalid_vm_return_http_204
    get '/control/esxi/vm/0/off'

    assert_equal(204, last_response.status)
  end

  def test_esxi_vm_force_off_should_call_gateway_and_return_http_204
    get '/control/esxi/vm/1/off!'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_vm_force_off_invalid_vm_return_http_404
    get '/control/esxi/vm/0/off!'

    assert_equal(404, last_response.status)
  end

  def test_esxi_schedule_enable_shoud_call_gateway_and_return_http_204
    get '/control/esxi/schedule/enable/07:00/02:00'

    assert_equal(204, last_response.status)
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
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
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_schedule_status_should_return_json_and_http_200
    get '/control/esxi/schedule/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('07:00', parsed_object[:status][:on_at])
    assert_equal('02:00', parsed_object[:status][:off_at])
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
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
    assert_equal(5, parsed_object[:disks].size)

    disk1 = parsed_object[:disks][0]
    assert_equal(1, disk1[:id])
    assert_equal('t10.ATA_____ST2000DL0032D9VT166__________________________________5YD1XA4F', disk1[:tech_id])
    assert_equal('ST2000DL0032D9VT166', disk1[:model])
    assert_equal('CC32', disk1[:revision])
    assert_equal(1863.0, disk1[:size_gigabytes])
    assert_equal('5YD1XA4F', disk1[:serial_no])
    assert_equal('t10.ATA', disk1[:port])
    assert_equal('/vmfs/devices/disks/t10.ATA_____ST2000DL0032D9VT166__________________________________5YD1XA4F', disk1[:device])
    disk2 = parsed_object[:disks][1]
    assert_equal(2, disk2[:id])
    assert_equal('t10.ATA_____ST2000DL0032D9VT166__________________________________5YD2HWZ3', disk2[:tech_id])
    disk3 = parsed_object[:disks][2]
    assert_equal(3, disk3[:id])
    assert_equal('t10.ATA_____ST3000VN0002D1H4167__________________________________W300GKNA', disk3[:tech_id])
    disk4 = parsed_object[:disks][3]
    assert_equal(4, disk4[:id])
    assert_equal('t10.ATA_____ST3000VN0002D1H4167__________________________________W300H4CK', disk4[:tech_id])
    disk5 = parsed_object[:disks][4]
    assert_equal(5, disk5[:id])
    assert_equal('t10.ATA_____WDC_WD2500BEVT2D75ZCT2________________________WD2DWXH109031153', disk5[:tech_id])
    assert_equal('WD2500BEVT2D75ZCT2', disk5[:model])
    assert_equal('WD2DWXH109031153', disk5[:serial_no])
    assert_equal('t10.ATA', disk5[:port])

    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_status_when_ping_ok_should_return_json_and_http_200
    @system_gateway.ssh_error = true

    get '/control/esxi/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('UP', parsed_object[:status])
    assert_true(@system_gateway.called?, 'Unproper call to system gateway')
  end

  def test_esxi_status_when_running_should_return_json_and_http_200
    @system_gateway.ssh_error = false

    get '/control/esxi/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('UP, RUNNING', parsed_object[:status])
  end

  def test_esxi_status_when_off_should_return_json_and_http_200
    @system_gateway.esxi_off = true

    get '/control/esxi/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('DOWN', parsed_object[:status])
  end

  def test_esxi_disk_smart_single_and_invalid_disk_id_should_return_http_400
    get '/control/esxi/disk/bla/smart.json'

    assert_equal(400, last_response.status)
  end

  def test_esxi_disk_smart_single_and_unknown_disk_id_should_return_http_404
    get '/control/esxi/disk/1255/smart.json'

    assert_equal(404, last_response.status)
  end

  def test_esxi_disk_smart_single_should_return_json_and_http_200
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)

    assert_smart_info(parsed_object[:smart])
  end

  def test_esxi_disks_smart_multi_should_return_json_and_http_200
    get '/control/esxi/disks/1,2/smart.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert(parsed_object[:disks_smart].is_a? Array)
    assert_equal(2, parsed_object[:disks_smart].size)

    disk2 = parsed_object[:disks_smart][1]
    assert_equal('2', disk2[:disk_id])

    assert_smart_info(disk2[:smart])
  end

  def test_esxi_disks_smart_multi_and_invalid_disk_list_should_return_http_400
    # Case 1: wrong separator
    get '/control/esxi/disks/1;2/smart.json'

    assert_equal(400, last_response.status)

    # Case 2: wrong id format
    get '/control/esxi/disks/1,a/smart.json'

    assert_equal(400, last_response.status)    # Case 2: wrong id format

    # Case 3: missing value (middle)
    get '/control/esxi/disks/1,,3/smart.json'

    assert_equal(400, last_response.status)
    
    # Case 4: missing value (end)
    get '/control/esxi/disks/1,2,/smart.json'

    assert_equal(400, last_response.status)    # Case 4: missing value

    # Case 5: missing value (start)
    get '/control/esxi/disks/,2/smart.json'

    assert_equal(400, last_response.status)
  end

  def test_esxi_disks_smart_multi_and_one_unknown_disk_id_should_return_http_404
    get '/control/esxi/disks/1,2,345/smart.json'

    assert_equal(404, last_response.status)
  end

  # Utilities
  private
  def assert_smart_info(smart_info)
    assert_equal('OK', smart_info[:i_status])
    assert(smart_info[:items].is_a? Array)
    assert_equal(13, smart_info[:items].size)

    item1 = smart_info[:items][0]
    assert_equal(1, item1[:id])

    assert_equal('Health Status', item1[:label])
    assert_equal('OK', item1[:value])
    assert_equal('N/A', item1[:threshold])
    assert_equal('N/A', item1[:worst])
    assert_equal('OK', item1[:status])
    item2 = smart_info[:items][1]
    assert_equal(2, item2[:id])
    item3 = smart_info[:items][2]
    assert_equal(3, item3[:id])
    item4 = smart_info[:items][3]
    assert_equal(4, item4[:id])
  end    
end