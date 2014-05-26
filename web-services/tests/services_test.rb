# services_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
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

    @big_brother_file_name = Services::BIG_BROTHER_LOG_FILE_NAME
    # Can only be deleted on first time
    File::delete(@big_brother_file_name) rescue nil
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

  def test_esxi_on_should_tell_big_brother
    assert_big_brother('/control/esxi/on', ' to turn on.')
  end

  def test_esxi_off_should_tell_big_brother
    assert_big_brother('/control/esxi/off', ' to turn off.')
  end

  def test_esxi_vms_should_tell_big_brother
    assert_big_brother('/control/esxi/vms.json', ' has just requested virtual machines list.')
  end

  def test_esxi_vm_status_should_tell_big_brother
    assert_big_brother('/control/esxi/vm/1/status.json', ' has just requested status of virtual machine #1.')
  end

  def test_big_brother_should_return_json_and_http_200
    get '/big_brother.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_kind_of(Array, parsed_object[:events])
  end

  def test_big_brother_should_tell_big_brother
    assert_big_brother('/big_brother.json', ' has just requested big brother contents.')
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

  def test_esxi_schedule_enable_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/enable/07:00/02:00', ' has just requested scheduling of')
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

  def test_esxi_schedule_disable_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/disable', ' has just requested to stop scheduling of')
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

  def test_esxi_schedule_status_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/status.json', ' has just requested scheduling status of')
  end

  def test_esxi_disk_list_should_return_json_and_http_200
    get '/control/esxi/disks.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert(parsed_object[:disks].is_a? Array)
    #TODO : Assert contents
  end

  def test_esxi_disk_list_should_tell_big_brother
    assert_big_brother('/control/esxi/disks.json', ' has just requested disk list.')
  end


  #Utilities
  def assert_big_brother(path, included_expression)
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get path

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(included_expression))
  end

end

# Used for testing : mocks system calls
class SystemGatewayMock

  attr_accessor :verify, :ssh_error, :scheduling_stopped

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @verify = false
    @ssh_error = false
    @scheduling_stopped = false
  end

  def ssh(host, user_name, command)
    raise 'Undefined host' if host.nil?
    raise 'Undefined user' if user_name.nil?

    # To simulate errors
    if @ssh_error
      @ssh_error = false
      raise(SSHError)
    end

    case command
      when 'poweroff'
        out = ''
      when 'vim-cmd vmsvc/getallvms'
        # Important : use double quotes here to take new lines into account !!
        out = "Vmid            Name                                          File                                      Guest OS          Version   Annotation\n01     xpenology-3810-esxi-1.1   [XXXXXXXXXX] ???????????????????????????????????????.vmx       other26xLinux64Guest    vmx-09              \n02     xpenology-4458-gnoboot    [XXXXXXXXXX] ?????????????????????????????????????????????.vmx   other26xLinux64Guest    vmx-09              \n"
      when 'vim-cmd vmsvc/power.getstate 1'
        out = "Retrieved runtime info\nPowered on\n"
      when 'vim-cmd vmsvc/power.getstate 0'
        out = ''
      when 'esxcli storage core device list'
        out = "t10.ATA_ST3000VN0002D1H4167__W300H4CK\n Display Name: Local ATA Disk (t10.ATA_ST3000VN0002D1H4167__W300H4CK)\n Has Settable Display Name: true\n Size: 2861588\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST3000VN0002D1H4167__W300H4CK\n Vendor: ATA \n Model: ST3000VN000-1H41\n Revision: SC43\nSCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.0100000000202020202020202020202020573330304834434b535433303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST2000DL0032D9VT166__5YD2HWZ3\n Display Name: Local ATA Disk (t10.ATA_ST2000DL0032D9VT166__5YD2HWZ3)\n Has Settable Display Name: true\n Size: 1907729\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST2000DL0032D9VT166__5YD2HWZ3\n Vendor: ATA\n Model: ST2000DL003-9VT1\n Revision: CC32\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.01000000002020202020202020202020203559443248575a33535432303030\nIs Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nmpx.vmhba33:C0:T0:L0\n Display Name: Local USB Direct-Access (mpx.vmhba33:C0:T0:L0)\n Has Settable Display Name: false\nSize: 3819\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/mpx.vmhba33:C0:T0:L0\n Vendor: SanDisk \n Model: Cruzer Blade \n Revision: 1.26\n SCSI Level: 2\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: true\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unsupported\n Other UIDs: vml.0000000000766d68626133333a303a30\n Is Local SAS Device: false\n Is Boot USB Device: true\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST2000DL0032D9VT166__5YD1XA4F\n Display Name: Local ATA Disk (t10.ATA_ST2000DL0032D9VT166__5YD1XA4F)\n Has Settable Display Name: true\n Size: 1907729\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST2000DL0032D9VT166__5YD1XA4F\n Vendor: ATA \n Model: ST2000DL003-9VT1\n Revision: CC32\n SCSI Level: 5\nIs Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\nThin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.01000000002020202020202020202020203559443158413446535432303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153\n Display Name: Local ATA Disk (t10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153)\n Has Settable Display Name: true\n Size: 238475\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153\n Vendor: ATA \n Model: WDC WD2500BEVT-7\n Revision: 11.0\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.0100000000202020202057442d575848313039303331313533574443205744\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST3000VN0002D1H4167__W300GKNA\n Display Name: Local ATA Disk (t10.ATA_ST3000VN0002D1H4167__W300GKNA)\n Has Settable Display Name: true\n Size: 2861588\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST3000VN0002D1H4167__W300GKNA\n Vendor: ATA \n Model: ST3000VN000-1H41\n Revision: SC43\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.010000000020202020202020202020202057333030474b4e41535433303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n"
      else
        raise "Unexpected command: #{command}"
    end

    @verify = true
    out
  end

  def wakeonlan(mac_address, broadcast_address)
    raise 'Undefined server MAC address' if mac_address.nil?
    raise 'Undefined LAN broadcast address' if broadcast_address.nil?
    @verify = true
  end

  def crontab_add(id, entry)
    raise 'Wrong task id' if id != Services::CRONTAB_ID_ON and id != Services::CRONTAB_ID_OFF
    raise 'Undefined cron entry' if entry.nil?
    raise 'Undefined cron entry hour' if entry[:hour].nil?
    raise 'Undefined cron entry minute' if entry[:minute].nil?
    raise 'Undefined cron entry command' if entry[:command] != Services::CRONTAB_CMD_ON and entry[:command] != Services::CRONTAB_CMD_OFF
    @verify = true
  end

  def crontab_remove(*ids)
    raise 'Wrong task id list' if ids.nil? or ids.empty?
    @verify = true
  end

  def crontab_list
    @verify = true
    #To simulate disabled schedule
    if @scheduling_stopped
      @scheduling_stopped = false
      return {}
    end

    {
        "#{Services::CRONTAB_ID_ON}" => "0\t7\t*\t*\t*\tcurl http://foo/on",
        "#{Services::CRONTAB_ID_OFF}" => "0\t2\t*\t*\t*\tcurl http://foo/off"
    }
  end

end