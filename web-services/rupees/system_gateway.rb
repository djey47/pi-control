# system_gateway.rb - executes linux shell commands and applications. Acts as a wrapper, which can be overriden.

require 'logger'
require 'cronedit'
require_relative 'model/ssh_error'

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

    # SSH command failures (host unreachable, authentication errors)
    if $?.to_i != 0
      @logger.error("[SystemGateway][ssh] Command terminated abnormally: #{$?}")
      raise(SSHError)
    end

    @logger.info("[SystemGateway][ssh] Command ended. Output: #{out}")
    out
  end

  # Wakes device with specified mac address
  def wakeonlan(mac_address, broadcast_address)
    cmd = "wakeonlan -i #{broadcast_address} #{mac_address}"
    @logger.info("[SystemGateway][wakeonlan] Executing #{cmd}...")
    out = `#{cmd}`
    @logger.info("[SystemGateway][wakeonlan] Command ended. Output: #{out}")
  end

  def crontab_add(id, entry)
    @logger.info("[SystemGateway][crontab_add] Calling CronEdit::Crontab.Add(#{id}, #{entry})...")
    CronEdit::Crontab.Add(id, entry)
    @logger.info('[SystemGateway][crontab_add] Call ended.')
  end

  def crontab_remove(*ids)
    @logger.info("[SystemGateway][crontab_remove] Calling CronEdit::Crontab.Remove(#{ids})...")
    CronEdit::Crontab.Remove(ids)
    @logger.info('[SystemGateway][crontab_remove] Call ended.')
  end

  def crontab_list
    @logger.info('[SystemGateway][crontab_list] Calling CronEdit::Crontab.List...')
    list = CronEdit::Crontab.List
    @logger.info('[SystemGateway][crontab_remove] Call ended.')
    list
  end
end