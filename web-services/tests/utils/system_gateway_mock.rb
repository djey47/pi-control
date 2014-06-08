# system_gateway_modk.reb - Used for testing : mocks system calls

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
        # Important : use double quotes here to take new lines into account !!
        out = "Vmid            Name                                          File                                      Guest OS          Version   Annotation\n01     xpenology-3810-esxi-1.1   [XXXXXXXXXX] ???????????????????????????????????????.vmx       other26xLinux64Guest    vmx-09              \n02     xpenology-4458-gnoboot    [XXXXXXXXXX] ?????????????????????????????????????????????.vmx   other26xLinux64Guest    vmx-09              \n"
      when 'vim-cmd vmsvc/power.getstate 1'
        out = "Retrieved runtime info\nPowered on\n"
      when 'vim-cmd vmsvc/power.getstate 0'
        out = ''
      when 'esxcli storage core device list'
        out = "t10.ATA_ST3000VN0002D1H4167__W300H4CK\n Display Name: Local ATA Disk (t10.ATA_ST3000VN0002D1H4167__W300H4CK)\n Has Settable Display Name: true\n Size: 2861588\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST3000VN0002D1H4167__W300H4CK\n Vendor: ATA \n Model: ST3000VN000-1H41\n Revision: SC43\nSCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.0100000000202020202020202020202020573330304834434b535433303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST2000DL0032D9VT166__5YD2HWZ3\n Display Name: Local ATA Disk (t10.ATA_ST2000DL0032D9VT166__5YD2HWZ3)\n Has Settable Display Name: true\n Size: 1907729\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST2000DL0032D9VT166__5YD2HWZ3\n Vendor: ATA\n Model: ST2000DL003-9VT1\n Revision: CC32\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.01000000002020202020202020202020203559443248575a33535432303030\nIs Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nmpx.vmhba33:C0:T0:L0\n Display Name: Local USB Direct-Access (mpx.vmhba33:C0:T0:L0)\n Has Settable Display Name: false\nSize: 3819\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/mpx.vmhba33:C0:T0:L0\n Vendor: SanDisk \n Model: Cruzer Blade \n Revision: 1.26\n SCSI Level: 2\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: true\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unsupported\n Other UIDs: vml.0000000000766d68626133333a303a30\n Is Local SAS Device: false\n Is Boot USB Device: true\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST2000DL0032D9VT166__5YD1XA4F\n Display Name: Local ATA Disk (t10.ATA_ST2000DL0032D9VT166__5YD1XA4F)\n Has Settable Display Name: true\n Size: 1907729\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST2000DL0032D9VT166__5YD1XA4F\n Vendor: ATA \n Model: ST2000DL003-9VT1\n Revision: CC32\n SCSI Level: 5\nIs Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\nThin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.01000000002020202020202020202020203559443158413446535432303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153\n Display Name: Local ATA Disk (t10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153)\n Has Settable Display Name: true\n Size: 238475\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_WDC_WD2500BEVT2D75ZCT2__WD2DWXH109031153\n Vendor: ATA \n Model: WDC WD2500BEVT-7\n Revision: 11.0\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.0100000000202020202057442d575848313039303331313533574443205744\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n\nt10.ATA_ST3000VN0002D1H4167__W300GKNA\n Display Name: Local ATA Disk (t10.ATA_ST3000VN0002D1H4167__W300GKNA)\n Has Settable Display Name: true\n Size: 2861588\n Device Type: Direct-Access \n Multipath Plugin: NMP\n Devfs Path: /vmfs/devices/disks/t10.ATA_ST3000VN0002D1H4167__W300GKNA\n Vendor: ATA \n Model: ST3000VN000-1H41\n Revision: SC43\n SCSI Level: 5\n Is Pseudo: false\n Status: on\n Is RDM Capable: false\n Is Local: true\n Is Removable: false\n Is SSD: false\n Is Offline: false\n Is Perennially Reserved: false\n Queue Full Sample Size: 0\n Queue Full Threshold: 0\n Thin Provisioning Status: unknown\n Attached Filters: \n VAAI Status: unknown\n Other UIDs: vml.010000000020202020202020202020202057333030474b4e41535433303030\n Is Local SAS Device: false\n Is Boot USB Device: false\n No of outstanding IOs with competing worlds: 32\n"
      when 'esxcli storage core device smart get -d t10.ATA_ST2000DL0032D9VT166__5YD2HWZ3'
        out = "Parameter                     Value  Threshold  Worst\n----------------------------  -----  ---------  -----\nHealth Status                 OK     N/A        N/A  \nMedia Wearout Indicator       N/A    N/A        N/A  \nWrite Error Count             N/A    N/A        N/A  \nRead Error Count              116    6          99   \nPower-on Hours                79     0          79   \nPower Cycle Count             100    20         100  \nReallocated Sector Count      100  36         100  \nRaw Read Error Rate           116    6          99   \nDrive Temperature             35     0          45   \nDriver Rated Max Temperature  65     45         55   \nWrite Sectors TOT Count       200    0          200  \nRead Sectors TOT Count        N/A    N/A        N/A  \nInitial Bad Block Count       100    99         100  \n"
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