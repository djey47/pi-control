# services.rb - pi-control services

require 'logger'
require 'diskcached'
require_relative 'controller'
require_relative 'common/configuration'
require_relative 'model/disk'
require_relative 'model/disk_smart'
require_relative 'model/smart_item'
require_relative 'model/virtual_machine'
require_relative 'model/schedule_status'
require_relative 'model/disk_not_found_error'
require_relative 'model/v_m_not_found_error'
require_relative 'model/invalid_argument_error'
require_relative 'model/ssh_error'
require_relative 'utils/csv_to_hashes'
require_relative 'utils/smart_status_helper'

#noinspection RailsParamDefResolve
class Services

  #Default parameters
  SHELL_CMD = 'uname'

  #Machine states
  VM_POWERED_ON = 'Powered on'
  VM_POWERED_OFF = 'Powered off'

  #CRONTAB placeholders and commands
  CRONTAB_ID_ON = 'ESXI_ON'
  CRONTAB_ID_OFF = 'ESXI_OFF'
  CRONTAB_CMD_ON = "curl http://localhost:#{Configuration::get.app_server_port}/control/esxi/on"
  CRONTAB_CMD_OFF = "curl http://localhost:#{Configuration::get.app_server_port}/control/esxi/off"

  #Cache keys (diskcached)
  CACHE_KEY_DISKS = 'DISKS'
  CACHE_KEY_SMART_PREFIX = 'SMART_'

  #Cache parameters
  CACHE_EXPIRY_DISKS_SECS = 3600
  CACHE_EXPIRY_SMART_SECS = 30

  def initialize(system_gateway)

    @system_gateway = system_gateway

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    # Caching
    @disks_cache = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_DISKS_SECS)
    @smart_cache = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_SMART_SECS)
  end

  def esxi_off
    @logger.info('[Services][esxi_off]')

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    @system_gateway.ssh(host_name, user, 'poweroff')
  end

  def esxi_on
    @logger.info('[Services][esxi_on]')

    mac_address = Configuration::get.esxi_mac_address
    broadcast_address = Configuration::get.lan_broadcast_address

    @system_gateway.wakeonlan(mac_address, broadcast_address)
  end

  def get_big_brother
    @logger.info('[Services][big_brother.json]')

    File.new(Controller::BIG_BROTHER_LOG_FILE_NAME).readlines
  end

  def get_virtual_machines
    @logger.info('[Services][vms.json]')

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, 'vim-cmd vmsvc/getallvms')

    vms = []
    # Note : use double quotes with symbols
    out.split("\n").each_with_index do |line, index|
      # First line is ignored (header)
      unless index == 0
        valid_items = []
        line.split('   ').each do |item|
          valid_items << item.strip unless item.strip.empty?
        end
        if valid_items.length >= 4
          id = valid_items[0].strip
          name = valid_items[1].strip
          guest_os = valid_items[3].strip

          @logger.debug("id=#{id}, name=#{name}, guest_os=#{guest_os}")
          vms << VirtualMachine.new(id, name, guest_os)
        end
      end
    end
    vms
  end

  def get_virtual_machine_status(id)
    @logger.info('[Services][vm_status.json]')

    validate_vm_id(id)

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, "vim-cmd vmsvc/power.getstate #{id}")

    lines = out.split("\n")

    if lines.length == 2
      # First line is ignored
      status_label = lines[1]

      @logger.debug("id=#{id}, status=#{status_label}")

      if status_label == VM_POWERED_ON
        vm_status = 'ON'
      elsif status_label == VM_POWERED_OFF
        vm_status = 'OFF'
      else
        vm_status = '???'
      end
    else
      raise(VMNotFoundError.new, "Invalid VM id=#{id}")
    end
    vm_status
  end

  def virtual_machine_on(id)
    @logger.info('[Services][vm_on]')

    validate_vm_id(id)

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, "vim-cmd vmsvc/power.on #{id}")

    raise(VMNotFoundError.new, "Invalid VM id=#{id}") if out == ''
  end

  def virtual_machine_off(id)
    @logger.info('[Services][vm_off]')

    validate_vm_id(id)

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    @system_gateway.ssh(host_name, user, "vim-cmd vmsvc/power.shutdown #{id}")
  end

  def virtual_machine_off!(id)
    @logger.info('[Services][vm_off!]')

    validate_vm_id(id)

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, "vim-cmd vmsvc/power.off #{id}")

    raise(VMNotFoundError.new, "Invalid VM id=#{id}") if out == ''
    end

  def enable_schedule(on_time, off_time)
    @logger.info('[Services][enable_schedule]')

    on_hour, on_minute = validate_parse_time(on_time)
    off_hour, off_minute = validate_parse_time(off_time)

    @logger.debug("ON COMMAND=#{CRONTAB_CMD_ON}, OFF COMMAND=#{CRONTAB_CMD_OFF}")

    @system_gateway.crontab_add(CRONTAB_ID_ON, {:hour => on_hour, :minute => on_minute, :command => CRONTAB_CMD_ON})
    @system_gateway.crontab_add(CRONTAB_ID_OFF, {:hour => off_hour, :minute => off_minute, :command => CRONTAB_CMD_OFF})
  end

  def disable_schedule
    @logger.info('[Services][disable_schedule]')

    @system_gateway.crontab_remove(CRONTAB_ID_ON, CRONTAB_ID_OFF)
  end

  def get_schedule_status
    @logger.info('[Services][schedule_status.json]')

    entries = @system_gateway.crontab_list

    on_entry = entries[CRONTAB_ID_ON]
    off_entry = entries[CRONTAB_ID_OFF]

    return ScheduleStatus.new if on_entry.nil? or off_entry.nil?

    on_time = parse_cron_entry(on_entry)
    off_time = parse_cron_entry(off_entry)
    ScheduleStatus.new(on_time, off_time)
  end

  # Cached
  def get_disks
    @logger.info('[Services][disks.json] Requesting cache...')

    @disks_cache.cache(CACHE_KEY_DISKS) do
      @logger.info('[Services][disks.json] Cache miss!')
      get_disks_uncached
    end
  end
  def get_disks_uncached
    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, 'esxcli --formatter=csv storage core device list')

    #Gathering all drives and Filtering to keep only hard disks
    hard_disks = CSVToHashes::convert(out).select { |drive| drive['IsBootUSBDevice'] == 'false' }

    #Sorting by technical id
    hard_disks.sort! { |hd1, hd2| hd1['Device'] <=> hd2['Device'] }

    #Mapping to disks structure
    hard_disks.map.with_index { |hd, index|

      # Converts size from mb to gb
      size_megabytes = hd['Size']
      size_gigabytes = (size_megabytes.to_i / 1024).round(4)

      # Extracts additional, more reliable information from ID
      complement = hd['Device'].split('_').select! { |item| item.length > 0 }
      port = complement[0]

      # As hd['Model'] is incomplete
      full_model = 'N/A'
      serial_no = 'N/A'
      if complement.length == 3
        full_model = complement[1]
        serial_no = complement[2]
      elsif complement.length == 4
        # Hack for WD disks : rank 1 is just WDC brand name
        full_model = complement[2]
        serial_no = complement[3]
      end

      Disk.new(
          index + 1,
          hd['Device'],
          full_model,
          hd['Revision'],
          size_gigabytes,
          hd['DevfsPath'],
          serial_no,
          port
      )
    }
  end

  def get_esxi_status
    # If responds to ping => UP, if basic SSH command completes => UP, RUNNING
    # Else DOWN
    @logger.info('[Services][esxi_status.json]')

    host_name = Configuration::get.esxi_host_name

    responds_to_ping = @system_gateway.ping(host_name, 4)

    if responds_to_ping
      @logger.info("[Services][esxi_status.json] Host #{host_name} responds to ping.")

      user = Configuration::get.esxi_user

      begin
        @system_gateway.ssh(host_name, user, SHELL_CMD)

        @logger.info("[Services][esxi_status.json] Host #{host_name} responds to SSH.")

        'UP, RUNNING'
      rescue SSHError
        @logger.info("[Services][esxi_status.json] Host #{host_name} does not respond to SSH.")

        'UP'
      end

    else
      @logger.info("[Services][esxi_status.json] Host #{host_name} does not even respond to ping.")

      'DOWN'
    end
  end

  # Cached
  def get_smart(disk_id)
    @logger.info('[Services][disk_smart.json] Requesting cache...')

    @smart_cache.cache("#{CACHE_KEY_SMART_PREFIX}#{disk_id}") do
      @logger.info('[Services][disk_smart.json] Cache miss!')
      get_smart_uncached(disk_id)
    end
  end
  def get_smart_uncached(disk_id)

    validate_disk_id(disk_id)

    tech_id = get_disk_tech_id(disk_id)

    unless tech_id.nil?
      # Requests SMART data
      host_name = Configuration::get.esxi_host_name
      user = Configuration::get.esxi_user
      out = @system_gateway.ssh(host_name, user, "esxcli --formatter=csv storage core device smart get -d #{tech_id}")

      items = CSVToHashes::convert(out).map.with_index { |item, index |

        label = item['Parameter']
        value = item['Value']
        threshold = item['Threshold']
        worst = item['Worst']
        status = SMARTStatusHelper::get_status(label, value, worst, threshold)

        SmartItem.new(
          index + 1,
          label,
          value,
          worst,
          threshold,
          status)
      }

      global_status = SMARTStatusHelper.get_global_status(items)

      return DiskSmart.new(global_status, items)
    end

    raise(DiskNotFoundError.new, "Invalid disk id=#{disk_id}")
  end

  def get_smart_multi(disk_ids)
    @logger.info('[Services][disks_smart.json]')

    tech_ids = disk_ids.map { |id|
      get_disk_tech_id(id)
    }

    cmds = ''
    tech_ids.each_with_index do |tech_id, index|
      cmds << "esxcli --formatter=csv storage core device smart get -d #{tech_id}"
      cmds << ';' if index < tech_ids.size - 1
    end

    # Requests SMART data
    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user
    out = @system_gateway.ssh(host_name, user, cmds)

  end

  private
  #Utilities
  def parse_cron_entry(entry)
    items = entry.split("\t")

    hours = items[1].rjust(2, '0')
    minutes = items[0].rjust(2, '0')
    "#{hours}:#{minutes}"
  end

  def get_disk_tech_id(disk_id)
    # Gets technical id from simple id
    get_disks.each do |disk|
      if disk.id == disk_id.to_i
        return disk.tech_id
      end
    end
    nil
  end

  #Input validators
  def validate_vm_id(id)
    val = Integer(id) rescue nil
    raise(InvalidArgumentError.new, "Invalid VM identifier: #{id}") if val.nil?
  end

  def validate_disk_id(id)
    val = Integer(id) rescue nil
    raise(InvalidArgumentError.new, "Invalid disk identifier: #{id}") if val.nil?
  end

  def validate_parse_time(time)
    #Format : HH:MM (24 hour format)
    /(?<hours>\d{1,2}):(?<minutes>\d{1,2})/.match(time) do |match_data|
      hrs = Integer(match_data['hours'], 10)
      mins = Integer(match_data['minutes'], 10)

      return hrs, mins if hrs.between?(0, 23) and mins.between?(0, 59)
    end
    raise(InvalidArgumentError.new, "Invalid time parameter: #{time}")
  end
end