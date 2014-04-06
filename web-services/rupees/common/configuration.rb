#configuration.rb - module to read config from yaml file
#Contents are not cached, thus will be read each time get method is invoked

require 'logger'
require 'yaml'

module Configuration

  CONFIG_FILE_NAME = './web-services/conf/pi-control.yml'

  class Conf < Struct.new(:app_is_production, :esxi_host_name, :esxi_user, :esxi_mac_address, :lan_broadcast_address)
  end

  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  # Reads configuration from given config file
  # @param [String] config_file_name
  # @return [Conf] structure containing all parameters
  def self.get(config_file_name = CONFIG_FILE_NAME)

    begin
      contents = YAML.load_file(config_file_name)

      app_is_production = contents['app']['is-production']
      host_name = contents['esxi']['host-name']
      user = contents['esxi']['user']
      mac_address = contents['esxi']['mac-address']
      broadcast_address = contents['lan']['broadcast-address']

    rescue => exception
      @logger.error("[Configuration] Config file not found or invalid! #{exception.inspect}")
      raise('Invalid configuration')
    end

    Conf.new(app_is_production, host_name, user, mac_address, broadcast_address)
  end
end