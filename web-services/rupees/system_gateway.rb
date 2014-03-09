# system_gateway.rb - executes linux shell commands and applications

require 'logger'

class SystemGateway
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def ssh(host, user_name, command)
    cmd = "ssh #{user_name}@#{host} #{command}"
    @logger.info("[SystemGateway][ssh] Executing #{cmd}...")
    out = `#{cmd}`
    @logger.info("[SystemGatewayMock][ssh] Command ended. Output: #{out}")
  end

end