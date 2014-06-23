# system_gateway_mock.rb - Used for testing : mocks system calls

require_relative '../../rupees/model/ssh_error'

class SystemGatewayMock

  attr_accessor :verify, :ssh_error, :scheduling_stopped, :esxi_off

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @verify = false
    @ssh_error = false
    @scheduling_stopped = false
    @esxi_off = false
  end

  def ssh(host, user_name, command)
    raise 'Undefined host' if host.nil?
    raise 'Undefined user' if user_name.nil?

    # To simulate errors
    if @ssh_error
      @ssh_error = false
      raise(SSHError)
    end

    case command
      when 'poweroff'
        out = ''
      when 'vim-cmd vmsvc/getallvms'
        out = "Vmid            Name                                          File                                      Guest OS          Version   Annotation\n01     xpenology-3810-esxi-1.1   [XXXXXXXXXX] ???????????????????????????????????????.vmx       other26xLinux64Guest    vmx-09              \n02     xpenology-4458-gnoboot    [XXXXXXXXXX] ?????????????????????????????????????????????.vmx   other26xLinux64Guest    vmx-09              \n"
      when 'vim-cmd vmsvc/power.getstate 1'
        out = "Retrieved runtime info\nPowered on\n"
      when 'vim-cmd vmsvc/power.getstate 0'
        out = ''
      when 'esxcli --formatter=csv storage core device list'
        out = "AttachedFilters,DevfsPath,Device,DeviceType,DisplayName,HasSettableDisplayName,IsBootUSBDevice,IsLocal,IsLocalSASDevice,IsOffline,IsPerenniallyReserved,IsPseudo,IsRDMCapable,IsRemovable,IsSSD,Model,MultipathPlugin,NoofoutstandingIOswithcompetingworlds,OtherUIDs,QueueFullSampleSize,QueueFullThreshold,Revision,SCSILevel,Size,Status,ThinProvisioningStatus,VAAIStatus,Vendor,\n,/vmfs/devices/disks/t10.ATA_____ST3000VN0002D1H4167__________________________________W300H4CK,t10.ATA_____ST3000VN0002D1H4167__________________________________W300H4CK,Direct-Access ,Local ATA Disk (t10.ATA_____ST3000VN0002D1H4167__________________________________W300H4CK),true,false,true,false,false,false,false,false,false,false,ST3000VN000-1H41,NMP,32,\"vml.0100000000202020202020202020202020573330304834434b535433303030,\",0,0,SC43,5,2861588,on,unknown,unknown,ATA     ,\n,/vmfs/devices/disks/t10.ATA_____ST2000DL0032D9VT166__________________________________5YD2HWZ3,t10.ATA_____ST2000DL0032D9VT166__________________________________5YD2HWZ3,Direct-Access ,Local ATA Disk (t10.ATA_____ST2000DL0032D9VT166__________________________________5YD2HWZ3),true,false,true,false,false,false,false,false,false,false,ST2000DL003-9VT1,NMP,32,\"vml.01000000002020202020202020202020203559443248575a33535432303030,\",0,0,CC32,5,1907729,on,unknown,unknown,ATA     ,\n,/vmfs/devices/disks/mpx.vmhba33:C0:T0:L0,mpx.vmhba33:C0:T0:L0,Direct-Access ,Local USB Direct-Access (mpx.vmhba33:C0:T0:L0),false,true,true,false,false,false,false,false,true,false,Cruzer Blade    ,NMP,32,\"vml.0000000000766d68626133333a303a30,\",0,0,1.26,2,3819,on,unknown,unsupported,SanDisk ,\n,/vmfs/devices/disks/t10.ATA_____ST2000DL0032D9VT166__________________________________5YD1XA4F,t10.ATA_____ST2000DL0032D9VT166__________________________________5YD1XA4F,Direct-Access ,Local ATA Disk (t10.ATA_____ST2000DL0032D9VT166__________________________________5YD1XA4F),true,false,true,false,false,false,false,false,false,false,ST2000DL003-9VT1,NMP,32,\"vml.01000000002020202020202020202020203559443158413446535432303030,\",0,0,CC32,5,1907729,on,unknown,unknown,ATA     ,\n,/vmfs/devices/disks/t10.ATA_____WDC_WD2500BEVT2D75ZCT2________________________WD2DWXH109031153,t10.ATA_____WDC_WD2500BEVT2D75ZCT2________________________WD2DWXH109031153,Direct-Access ,Local ATA Disk (t10.ATA_____WDC_WD2500BEVT2D75ZCT2________________________WD2DWXH109031153),true,false,true,false,false,false,false,false,false,false,WDC WD2500BEVT-7,NMP,32,\"vml.0100000000202020202057442d575848313039303331313533574443205744,\",0,0,11.0,5,238475,on,unknown,unknown,ATA     ,\n,/vmfs/devices/disks/t10.ATA_____ST3000VN0002D1H4167__________________________________W300GKNA,t10.ATA_____ST3000VN0002D1H4167__________________________________W300GKNA,Direct-Access ,Local ATA Disk (t10.ATA_____ST3000VN0002D1H4167__________________________________W300GKNA),true,false,true,false,false,false,false,false,false,false,ST3000VN000-1H41,NMP,32,\"vml.010000000020202020202020202020202057333030474b4e41535433303030,\",0,0,SC43,5,2861588,on,unknown,unknown,ATA     ,\n"
      when 'esxcli --formatter=csv storage core device smart get -d t10.ATA_____ST2000DL0032D9VT166__________________________________5YD2HWZ3'
        out = "Parameter,Threshold,Value,Worst,\nHealth Status,N/A,OK,N/A,\nMedia Wearout Indicator,N/A,N/A,N/A,\nWrite Error Count,N/A,N/A,N/A,\nRead Error Count,6,120,99,\nPower-on Hours,0,78,78,\nPower Cycle Count,20,100,100,\nReallocated Sector Count,36,100,100,\nRaw Read Error Rate,6,120,99,\nDrive Temperature,0,35,45,\nDriver Rated Max Temperature,45,65,55,\nWrite Sectors TOT Count,0,200,200,\nRead Sectors TOT Count,N/A,N/A,N/A,\nInitial Bad Block Count,99,100,100,\n"
      when 'uname'
        out = "VMkernel\n"
      else
        raise "Unexpected command: #{command}"
    end

    @verify = true
    out
  end

  def wakeonlan(mac_address, broadcast_address)
    raise 'Undefined server MAC address' if mac_address.nil?
    raise 'Undefined LAN broadcast address' if broadcast_address.nil?
    @verify = true
  end

  def crontab_add(id, entry)
    raise 'Wrong task id' if id != Services::CRONTAB_ID_ON and id != Services::CRONTAB_ID_OFF
    raise 'Undefined cron entry' if entry.nil?
    raise 'Undefined cron entry hour' if entry[:hour].nil?
    raise 'Undefined cron entry minute' if entry[:minute].nil?
    raise 'Undefined cron entry command' if entry[:command] != Services::CRONTAB_CMD_ON and entry[:command] != Services::CRONTAB_CMD_OFF
    @verify = true
  end

  def crontab_remove(*ids)
    raise 'Wrong task id list' if ids.nil? or ids.empty?
    @verify = true
  end

  def crontab_list
    @verify = true
    #To simulate disabled schedule
    if @scheduling_stopped
      @scheduling_stopped = false
      return {}
    end

    {
        "#{Services::CRONTAB_ID_ON}" => "0\t7\t*\t*\t*\tcurl http://foo/on",
        "#{Services::CRONTAB_ID_OFF}" => "0\t2\t*\t*\t*\tcurl http://foo/off"
    }
  end

  def ping(host, icmp_count = 1)
    raise 'Undefined host' if host.nil?

    # To simulate off device
    if @esxi_off
      @esxi_off = false
      return false
    end

    @verify = true

    true
  end
end