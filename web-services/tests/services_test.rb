# services_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative '../rupees/services'
require_relative '../rupees/model/virtual_machine'
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
    assert_equal(4, parsed_object[:virtualMachines].size, 'array size mismatch')
    vm = parsed_object[:virtualMachines][0]
    assert(vm[:id] == '13', 'id attribute mismatch')
    assert(vm[:name] == 'xpenology-3810-esxi-1.1', 'name attribute mismatch')
    assert(vm[:guest_os] == 'other26xLinux64Guest', 'guest_os attribute mismatch')
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

  def test_esxi_schedule_enable_return_http_204
    get '/control/esxi/schedule/enable/07:00/02:00'

    assert_equal(204, last_response.status)
  end

  def test_esxi_schedule_enable_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/enable/07:00/02:00', ' has just requested scheduling of')
  end

  def test_esxi_schedule_wrong_time_return_http_400
    get '/control/esxi/schedule/enable/aaaa/02:00'

    assert_equal(400, last_response.status)
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

  attr_accessor :verify, :ssh_error

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @verify = false
    @ssh_error = false
  end

  def ssh(host, user_name, command)
    raise 'Undefined host' if host.nil?
    raise 'Undefined user' if user_name.nil?

    # To simulate errors
    if (@ssh_error)
      @ssh_error = false
      raise(SSHError)
    end

    if command == 'poweroff'
      out = ''
    elsif command == 'vim-cmd vmsvc/getallvms'
      # Important : use double quotes here to taken new lines into account !!
      out = "Vmid               Name                                              File                                        Guest OS         Version   Annotation\n13     xpenology-3810-esxi-1.1        [Transverse] xpenology-3810-esxi/xpenology-3810-esxi.vmx             other26xLinux64Guest   vmx-09              \n14     xpenology-3810-esxi-1.1-test   [Transverse] xpenology-3810-esxi-test/xpenology-3810-esxi-test.vmx   other26xLinux64Guest   vmx-09              \n15     xpenology-dsm5b-test           [Transverse] xpenology-dsm5-test/xpenology-dsm5-test.vmx             other26xLinux64Guest   vmx-09              \n4      xubuntu-neo                    [Transverse] xubuntu-neo/xubuntu-neo.vmx                             ubuntu64Guest          vmx-08              \n"
    elsif command == 'vim-cmd vmsvc/power.getstate 1'
      out = "Retrieved runtime info\nPowered on\n"
    elsif command == 'vim-cmd vmsvc/power.getstate 0'
      out = ''
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
end