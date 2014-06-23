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

    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
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
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
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
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
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

    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
  end

  def test_esxi_status_when_ping_ok_should_return_json_and_http_200
    @system_gateway.ssh_error = true

    get '/control/esxi/status.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('UP', parsed_object[:status])
    assert_true(@system_gateway.verify, 'Unproper call to system gateway')
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

  def test_esxi_disk_smart_and_invalid_disk_id_should_return_http_400
    get '/control/esxi/disk/bla/smart.json'

    assert_equal(400, last_response.status)
  end

  def test_esxi_disk_smart_and_unknown_disk_id_should_return_http_404
    get '/control/esxi/disk/1255/smart.json'

    assert_equal(404, last_response.status)
  end

  def test_esxi_disk_smart_should_return_json_and_http_200
    get '/control/esxi/disk/2/smart.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_equal('<FAKE>', parsed_object[:smart][:i_status])
    assert(parsed_object[:smart][:items].is_a? Array)
    assert_equal(13, parsed_object[:smart][:items].size)

    item1 = parsed_object[:smart][:items][0]
    assert_equal(1, item1[:id])
    assert_equal('Health Status', item1[:label])
    assert_equal('OK', item1[:value])
    assert_equal('N/A', item1[:threshold])
    assert_equal('N/A', item1[:worst])
    assert_equal('<FAKE>', item1[:status])
    item2 = parsed_object[:smart][:items][1]
    assert_equal(2, item2[:id])
    item3 = parsed_object[:smart][:items][2]
    assert_equal(3, item3[:id])
    item4 = parsed_object[:smart][:items][3]
    assert_equal(4, item4[:id])
  end
end