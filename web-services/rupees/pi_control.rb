# pi_control.rb - app entry point

require 'singleton'
require 'logger'

require_relative './common/cache'
require_relative './common/configuration'

class PiControl
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def run
    @logger.info('[PiControl] Welcome!')

    @logger.info('[PiControl] Configuration self-check before starting...')
    begin
        Configuration::get
    rescue => exception
      @logger.error("[PiControl] #{exception.inspect}")
      return
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
end

# Boot
PiControl.instance.run
PiControl.instance.stop