# system_gateway.rb - executes linux shell commands and applications. Acts as a wrapper, which can be overriden.

require 'logger'
require_relative 'model/ssh_error'
require_relative 'utils/cronedit'

class SystemGateway

  # BatchMode keeps it from hanging with Host unknown, YES to add to known_hosts, and StrictHostKeyChecking adds the fingerprint automatically.
  SSH_OPTIONS = '-o BatchMode=yes -o StrictHostKeyChecking=no'

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  # Executes given commands via SSH onto specified host
  def ssh(host, user_name, *commands)
    global_cmd = "ssh #{SSH_OPTIONS} #{user_name}@#{host} \"#{commands.join(';')}\""
    @logger.info("[SystemGateway][ssh] Executing #{global_cmd}...")
    out = `#{global_cmd}`

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

  # Adds entry to crontab
  def crontab_add(id, entry)
    @logger.info("[SystemGateway][crontab_add] Calling CronEdit::Crontab.Add(#{id}, #{entry})...")
    CronEdit::Crontab.Add(id, entry)
    @logger.info('[SystemGateway][crontab_add] Call ended.')
  end

  # Removes entry from crontab
  def crontab_remove(*ids)
    @logger.info("[SystemGateway][crontab_remove] Calling CronEdit::Crontab.Remove(#{ids})...")
    CronEdit::Crontab.Remove(ids)
    @logger.info('[SystemGateway][crontab_remove] Call ended.')
  end

  # Returns current crontab entries
  def crontab_list
    @logger.info('[SystemGateway][crontab_list] Calling CronEdit::Crontab.List...')
    list = CronEdit::Crontab.List
    @logger.info("[SystemGateway][crontab_list] Call ended. Output: #{list}")
    list
  end

  # Pings specified host and returns true if OK, false if error
  def ping(host, icmp_count = 1)
    cmd = "ping -c #{icmp_count} #{host}"
    @logger.info("[SystemGateway][ping] Executing #{cmd}...")
    out = `#{cmd}`
    @logger.info("[SystemGateway][ping] Command ended. Output: #{out}")
    $? == 0
  end
end