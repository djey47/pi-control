# services_focus_on_big_brother_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

ENV['RACK_ENV'] = 'test'

require 'json'
require 'rack/test'
require 'test/unit'
require_relative 'utils/system_gateway_mock'
require_relative '../rupees/services'

class ServicesFocusOnBigBrotherTest < Test::Unit::TestCase
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