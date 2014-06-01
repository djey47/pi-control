# services.rb - REST http server

require 'json'
require 'logger'
require 'sinatra/base'
require_relative 'system_gateway'
require_relative 'common/configuration'
require_relative 'model/disk'
require_relative 'model/virtual_machine'
require_relative 'model/schedule_status'
require_relative 'model/v_m_not_found_error'
require_relative 'model/invalid_argument_error'
require_relative 'model/ssh_error'

#noinspection RailsParamDefResolve
class Services < Sinatra::Base

  #Default parameters
  SERVER_PORT = 4600
  BIG_BROTHER_LOG_FILE_NAME = './web-services/logs/big_brother.log'
  SHELL_CMD = 'uname'

  #Machine states
  VM_POWERED_ON = 'Powered on'
  VM_POWERED_OFF = 'Powered off'

  #CRONTAB placeholders and commands
  CRONTAB_ID_ON = 'ESXI_ON'
  CRONTAB_ID_OFF = 'ESXI_OFF'
  CRONTAB_CMD_ON = "curl http://localhost:#{SERVER_PORT}/control/esxi/on"
  CRONTAB_CMD_OFF = "curl http://localhost:#{SERVER_PORT}/control/esxi/off"

  #HTTP headers
  HDR_A_C_ALLOW_ORIGIN = 'Access-Control-Allow-Origin'
  HDR_ORIGIN = 'HTTP_ORIGIN'

  # To inject different gateways (real and mock)
  def initialize(system_gateway = SystemGateway.new)
    @system_gateway = system_gateway

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @big_brother = Logger.new(BIG_BROTHER_LOG_FILE_NAME)
    @big_brother.level = Logger::INFO

    super() #Required for correct Sinatra init
  end

  def esxi_off
    @logger.info('[Services][esxi_off]')

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    @system_gateway.ssh(host_name, user, 'poweroff')
    @big_brother.info("IP #{request.ip} has just requested #{host_name} to turn off.")
  end

  def esxi_on
    @logger.info('[Services][esxi_on]')

    mac_address = Configuration::get.esxi_mac_address
    broadcast_address = Configuration::get.lan_broadcast_address

    @system_gateway.wakeonlan(mac_address, broadcast_address)
    @big_brother.info("IP #{request.ip} has just requested device #{mac_address} to turn on.")
  end

  def get_big_brother
    @logger.info('[Services][big_brother.json]')

    @big_brother.info("IP #{request.ip} has just requested big brother contents.")
    File.new(BIG_BROTHER_LOG_FILE_NAME).readlines
  end

  def get_virtual_machines
    @logger.info('[Services][vms.json]')

    @big_brother.info("IP #{request.ip} has just requested virtual machines list.")

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

    @big_brother.info("IP #{request.ip} has just requested status of virtual machine ##{id}.")

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

  def enable_schedule(on_time, off_time)
    @logger.info('[Services][enable_schedule]')

    @big_brother.info("IP #{request.ip} has just requested scheduling of #{Configuration::get.esxi_host_name}: #{on_time}-#{off_time}.")

    on_hour, on_minute = validate_parse_time(on_time)
    off_hour, off_minute = validate_parse_time(off_time)

    @system_gateway.crontab_add(CRONTAB_ID_ON, {:hour => on_hour, :minute => on_minute, :command => CRONTAB_CMD_ON})
    @system_gateway.crontab_add(CRONTAB_ID_OFF, {:hour => off_hour, :minute => off_minute, :command => CRONTAB_CMD_OFF})
  end

  def disable_schedule
    @logger.info('[Services][disable_schedule]')

    @big_brother.info("IP #{request.ip} has just requested to stop scheduling of #{Configuration::get.esxi_host_name}.")

    @system_gateway.crontab_remove(CRONTAB_ID_ON, CRONTAB_ID_OFF)
  end

  def get_schedule_status
    @logger.info('[Services][schedule_status.json]')

    @big_brother.info("IP #{request.ip} has just requested scheduling status of #{Configuration::get.esxi_host_name}.")

    entries = @system_gateway.crontab_list

    on_entry  = entries[CRONTAB_ID_ON]
    off_entry  = entries[CRONTAB_ID_OFF]

    return ScheduleStatus.new(nil, nil) if on_entry.nil? or off_entry.nil?

    on_time = parse_cron_entry(on_entry)
    off_time = parse_cron_entry(off_entry)
    ScheduleStatus.new(on_time, off_time)
  end

  def get_disks
    @logger.info('[Services][disks.json]')

    @big_brother.info("IP #{request.ip} has just requested disk list.")

    host_name = Configuration::get.esxi_host_name
    user = Configuration::get.esxi_user

    out = @system_gateway.ssh(host_name, user, 'esxcli storage core device list')

    #Gathering all drives
    drives = []
    out.split("\n\n").each do |drive|
      drive_infos = {}
      drive.split("\n").each_with_index do |item, index|
        #First item is disk id
        if index == 0
          drive_infos.merge!( 'Id' => item )
        else
          key = item.split(':')[0].strip
          value = item.split(':')[1].strip
          drive_infos.merge!( key => value )
        end
      end
      drives << drive_infos
    end

    #Filtering to keep only hard disks
    disks = []
    drives.each do |drive|
      unless drive['Is Boot USB Device'] == 'true'
        size_megabytes = drive['Size']
        size_gigabytes = (size_megabytes.to_i / 1024).round(4)

        disks << Disk.new(
            drive['Id'],
            drive['Model'],
            size_gigabytes,
            drive['Devfs Path']
            #TODO Temp and status
        )
      end
    end
    disks
  end

  def get_esxi_status
    # If responds to ping => UP, if basic SSH command completes => UP, RUNNING
    # Else DOWN
    @logger.info('[Services][esxi_status.json]')

    @big_brother.info("IP #{request.ip} has just requested status of #{Configuration::get.esxi_host_name}.")

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

private
  #Utilities

  #XHR requests provide HTTP_ORIGIN header; for responses to be accepted, Access-Control-Allow-Origin header must be present in response
  def handle_headers_for_json
    response[HDR_A_C_ALLOW_ORIGIN] = request.env[HDR_ORIGIN] if request.env.has_key? HDR_ORIGIN
    content_type :json
  end

  def parse_cron_entry(entry)
    items = entry.split("\t")

    hours = items[1].rjust(2, '0')
    minutes = items[0].rjust(2, '0')
    "#{hours}:#{minutes}"
  end

  #Input validators
  def validate_vm_id(id)
    val = Integer(id) rescue nil
    raise(InvalidArgumentError.new, "Invalid VM identifier: #{id}") if val.nil?
  end

  def validate_parse_time(time)
    #Format : HH:MM (24 hour format)
    /(?<hours>\d{1,2}):(?<minutes>\d{1,2})/.match(time) do |match_data|
      hrs = Integer(match_data['hours'],10)
      mins = Integer(match_data['minutes'],10)

      return hrs, mins if hrs.between?(0, 23) and mins.between?(0, 59)
    end
    raise(InvalidArgumentError.new, "Invalid time parameter: #{time}")
  end

public
  #config
  set :port, SERVER_PORT
  if Configuration::get.app_is_production
    set :environment, :production
    set :show_exceptions, false
  else
    set :environment, :development
    set :show_exceptions, true
  end
  set :public_folder, File.dirname(__FILE__) + '/../public'

  #Heartbeat
  get '/' do
    @logger.info('[Services] Heartbeat!')
    [200, 'pi-control - webservices are alive :)']
  end

  #Turns esxi off
  get '/control/esxi/off' do
    begin
      esxi_off
      204
    rescue SSHError => exception
      @logger.error("[Services][esxi_off] #{exception.inspect}")
      503
    rescue => exception
      @logger.error("[Services][esxi_off] #{exception.inspect}")
      500
    end
  end

  #Turns esxi on
  get '/control/esxi/on' do
    begin
      esxi_on
      204
    rescue => exception
      @logger.error("[Services][esxi_on] #{exception.inspect}")
      500
    end
  end

  #Returns json with all big brother messages
  get '/big_brother.json' do
    begin
      handle_headers_for_json
      [200,
       {:events => get_big_brother}.to_json
      ]
    rescue => exception
      @logger.error("[Services][big_brother.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with all available virtual machines
  get '/control/esxi/vms.json' do
    begin
      handle_headers_for_json
      [200,
       {:virtualMachines => get_virtual_machines}.to_json
      ]
    rescue SSHError => err
      @logger.error("[Services][vms.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Services][vms.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of specified virtual machine
  get '/control/esxi/vm/:id/status.json' do |id|
    begin
      handle_headers_for_json
      [200,
       {:status => get_virtual_machine_status(id)}.to_json
      ]
    rescue InvalidArgumentError => err
      @logger.error("[Services][vm_status.json] #{err.inspect}")
      400
    rescue VMNotFoundError => err
      @logger.error("[Services][vm_status.json] #{err.inspect}")
      404
    rescue SSHError => err
      @logger.error("[Services][vm_status.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Services][vm_status.json] #{exception.inspect}")
      500
    end
  end

  #Enables ON/OFF scheduling at given times
  get '/control/esxi/schedule/enable/:on_time/:off_time' do |on_time, off_time|
    begin
      enable_schedule(on_time, off_time)
      204
    rescue InvalidArgumentError => err
      @logger.error("[Services][schedule_enable] #{err.inspect}")
      400
    rescue => exception
      @logger.error("[Services][schedule_enable] #{exception.inspect}")
      500
    end
  end

  #Disables ON/OFF scheduling
  get '/control/esxi/schedule/disable' do
    begin
      disable_schedule
      204
    rescue => exception
      @logger.error("[Services][schedule_disable] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of ON/OFF scheduling
  get '/control/esxi/schedule/status.json' do
    begin
      handle_headers_for_json
      [200,
       {:status => get_schedule_status}.to_json
      ]
    rescue => exception
      @logger.error("[Services][schedule_status.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with list of hard disks
  get '/control/esxi/disks.json' do
    begin
      handle_headers_for_json
      [200,
       {:disks => get_disks}.to_json
      ]
    rescue SSHError => err
      @logger.error("[Services][disks.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Services][disks.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of ESXI hypervisor
  get '/control/esxi/status.json' do
    begin
      handle_headers_for_json
      [200,
       {:status => get_esxi_status}.to_json
      ]
  #   rescue SSHError => err
  #     @logger.error("[Services][disks.json] #{err.inspect}")
  #     503
    rescue => exception
      @logger.error("[Services][esxi_status.json] #{exception.inspect}")
      500
    end
  end

end