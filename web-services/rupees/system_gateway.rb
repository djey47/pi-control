# system_gateway.rb - executes linux shell commands and applications

require 'logger'

class SystemGateway
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  # Executes given command via SSH onto specified host
  def ssh(host, user_name, command)
    cmd = "ssh #{user_name}@#{host} #{command}"
    @logger.info("[SystemGateway][ssh] Executing #{cmd}...")
    out = `#{cmd}`
    @logger.info("[SystemGateway][ssh] Command ended. Output: #{out}")
  end

  # Wakes device with specified mac address
  def wakeonlan(mac_address, broadcast_address)
    cmd = "wakeonlan -i #{broadcast_address} #{mac_address}"
    @logger.info("[SystemGateway][wakeonlan] Executing #{cmd}...")
    out = `#{cmd}`
    @logger.info("[SystemGateway][wakeonlan] Command ended. Output: #{out}")
  end
end