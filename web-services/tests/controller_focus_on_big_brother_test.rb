# controller_focus_on_big_brother_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative 'utils/system_gateway_mock'
require_relative '../rupees/controller'

class ControllerFocusOnBigBrotherTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Controller.new(@system_gateway)
  end

  def setup
    @system_gateway = SystemGatewayMock.new
    @json_parser_opts = {:symbolize_names => true}

    @big_brother_file_name = Controller::BIG_BROTHER_LOG_FILE_NAME
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

  def test_esxi_vm_on_should_tell_big_brother
    assert_big_brother('/control/esxi/vm/1/on', ' has just requested virtual machine #1 to turn on.')
  end

  def test_esxi_vm_off_should_tell_big_brother
    assert_big_brother('/control/esxi/vm/1/off', ' has just requested virtual machine #1 to turn off.')
  end

  def test_esxi_vm_force_off_should_tell_big_brother
    assert_big_brother('/control/esxi/vm/1/off!', ' has just requested virtual machine #1 to STOP.')
  end

  def test_esxi_schedule_enable_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/enable/07:00/02:00', ' has just requested scheduling of')
  end

  def test_esxi_schedule_disable_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/disable', ' has just requested to stop scheduling of')
  end

  def test_esxi_schedule_status_should_tell_big_brother
    assert_big_brother('/control/esxi/schedule/status.json', ' has just requested scheduling status of')
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

  def test_esxi_disk_list_should_tell_big_brother
    assert_big_brother('/control/esxi/disks.json', ' has just requested disk list.')
  end

  def test_esxi_status_should_tell_big_brother
    assert_big_brother('/control/esxi/status.json', ' has just requested status of ')
  end

  def test_esxi_disks_smart_should_tell_big_brother
    assert_big_brother('/control/esxi/disk/2/smart.json', ' has just requested SMART details of disk #2.')
  end

  def test_esxi_disks_smart_multi_should_tell_big_brother
    assert_big_brother('/control/esxi/disks/1,2/smart.json', ' has just requested SMART details of disks #1,2.')
  end

  #Utilities
  private
  def assert_big_brother(path, *included_expressions)
    big_brother_prev_contents = File.new(@big_brother_file_name).readlines

    get(path)

    assert(File.exists?(@big_brother_file_name))

    big_brother_new_contents = File.new(@big_brother_file_name).readlines
    assert_equal(big_brother_prev_contents.count + included_expressions.count, big_brother_new_contents.count)

    last_events = big_brother_new_contents.last(included_expressions.count)
    last_events.each_with_index { |event, index| assert(event.include?(included_expressions[index]))}
  end
end