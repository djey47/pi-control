#configuration_test.rb - Unit Tests
# Important : please set working directory to pi-control directory (not current dir), to resolve all paths correctly.

require 'test/unit'
require_relative '../../rupees/common/configuration'

class ConfigurationTest < Test::Unit::TestCase

  CONFIG_FILE_NAME = './web-services/tests/conf/pi-control.yml'
  CONFIG_FILE_NAME_NO_SERVER_PORT = './web-services/tests/conf/pi-control_no-server-port.yml'
  INVALID_CONFIG_FILE_NAME = './web-services/tests/conf/pi-control_invalid.yml'

  def test_get_should_return_conf_from_yaml

    config = Configuration::get(CONFIG_FILE_NAME)

    assert_equal(false, config.app_is_production, 'Invalid config value: app/is-production')
    assert_equal(4646, config.app_server_port, 'Invalid config value: app/server-port')
    assert_equal('test', config.esxi_host_name, 'Invalid config value: esxi/host-name')
    assert_equal('tester', config.esxi_user, 'Invalid config value: esxi/user')
    assert_equal('FF:FF:FF:FF:FF:FF', config.esxi_mac_address, 'Invalid config value: esxi/mac-address')
    assert_equal('192.168.1.255', config.lan_broadcast_address, 'Invalid config value: lan/broadcast-address')
  end

  def test_get_server_port_without_setting_should_return_default_value

    config = Configuration::get(CONFIG_FILE_NAME_NO_SERVER_PORT)

    assert_equal(4600, config.app_server_port, 'Invalid config value: app/server-port')
  end

  def test_get_invalid_config_file_then_exception

    begin
      Configuration::get(INVALID_CONFIG_FILE_NAME)
      fail
    rescue => exception
      assert_equal('Invalid configuration', exception.message)
    end
  end

  def test_get_no_config_file_then_exception

    begin
      Configuration::get('blah.yml')
      fail
    rescue => exception
      assert_equal('Invalid configuration', exception.message)
    end
  end
end