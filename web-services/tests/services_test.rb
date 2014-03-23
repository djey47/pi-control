# services_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative '../rupees/services'
require_relative '../rupees/model/virtual_machine'


class ServicesTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Services.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new
    @json_parser_opts = {:symbolize_names => true}
    @big_brother_file_name = Services::BIG_BROTHER_LOG_FILE_NAME
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

  def test_esxi_vms_should_tell_big_brother
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get '/control/esxi/vms.json'

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(' has just requested virtual machines list.'))
  end

  def test_big_brother_should_return_json_and_http_200
    get '/big_brother.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_kind_of(Array, parsed_object[:events])
  end

  def test_big_brother_should_tell_big_brother
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get '/big_brother.json'

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert(big_brother_new_contents.count == big_brother_prev_contents.count + 1)

    assert(big_brother_new_contents.last.include?(' has just requested big brother contents.'))
  end

  def test_esxi_vms_should_return_json_list_and_http_200
    get '/control/esxi/vms.json'

    assert_equal(200, last_response.status)
    parsed_object = JSON.parse(last_response.body, @json_parser_opts)
    assert_kind_of(Array, parsed_object[:virtualMachines])
    assert(parsed_object[:virtualMachines].size == 4)
    vm = parsed_object[:virtualMachines][0]
    assert(vm[:id] == '13', 'id attribute mismatch')
    assert(vm[:name] == 'xpenology-3810-esxi-1.1', 'name attribute mismatch')
    assert(vm[:guest_os] == 'other26xLinux64Guest', 'guest_os attribute mismatch')
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
    raise 'Undefined host' if host.nil?
    raise 'Undefined user' if user_name.nil?

    if command == 'poweroff'
      out = ''
    elsif command == 'vmsvc/getallvms'
      out = 'Vmid               Name                                              File                                        Guest OS         Version   Annotation\n13     xpenology-3810-esxi-1.1        [Transverse] xpenology-3810-esxi/xpenology-3810-esxi.vmx             other26xLinux64Guest   vmx-09              \n14     xpenology-3810-esxi-1.1-test   [Transverse] xpenology-3810-esxi-test/xpenology-3810-esxi-test.vmx   other26xLinux64Guest   vmx-09              \n15     xpenology-dsm5b-test           [Transverse] xpenology-dsm5-test/xpenology-dsm5-test.vmx             other26xLinux64Guest   vmx-09              \n4      xubuntu-neo                    [Transverse] xubuntu-neo/xubuntu-neo.vmx                             ubuntu64Guest          vmx-08              '
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