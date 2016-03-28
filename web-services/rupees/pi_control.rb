# pi_control.rb - app entry point

require 'singleton'
require 'logger'

require_relative 'system_gateway'
require_relative 'common/cache'
require_relative 'common/configuration'

class PiControl
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def run
    @logger.info('[PiControl] Welcome!')

    # SELF-CHECK should not prevent pi-control from starting (e.g when ESXI not ready or started, yet)
    begin
      self_check
    rescue => exception
      @logger.warn("[PiControl] #{exception.inspect}")
    end

    server_thread = Thread.new {
      @logger.info('[PiControl] Starting HTTP server...')
      require_relative 'controller'
      Controller.run!
    }
    @logger.info('[PiControl] Ready to rumble!')
    # Waiting for server thread to terminate
    server_thread.join
  end

  def stop
    @logger.info('[PiControl] Exiting pi-control...')

    begin
      Cache.instance.clear_all rescue nil
    rescue => exception
      @logger.error("[PiControl] #{exception.inspect}")
    end

    @logger.info('[PiControl] Goodbye!')
  end

  def self_check
    @logger.info('[PiControl] Configuration self-check before starting...')
    begin
        conf = Configuration::get

        SystemGateway.new.ssh_auto_check(conf.esxi_host_name, conf.esxi_user, 'vim-cmd', 'esxcli') if conf.app_is_production
    rescue => exception
      @logger.error("[PiControl] #{exception.inspect}")
      raise exception
    end
    @logger.info('[PiControl] Configuration self-check done!')
  end
end

# Boot
PiControl.instance.run
PiControl.instance.stop