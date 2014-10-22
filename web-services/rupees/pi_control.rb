# pi_control.rb - app entry point

require 'singleton'
require 'logger'
require_relative 'controller'

class PiControl
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def run
    server_thread = Thread.new {
      @logger.info('[PiControl] Starting HTTP server...')
      Controller.run!
    }
    @logger.info('[PiControl] Ready to rumble!')
    # Waiting for server thread to terminate
    server_thread.join
  end

  def stop
    @logger.info('[PiControl] Exiting pi-control...')

    Cache.instance.clear_all
  end
end

# Boot
PiControl.instance.run
PiControl.instance.stop