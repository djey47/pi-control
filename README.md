pi-control
==========

Set of web-services to control/monitor ESXi hypervisor from a linux-based, always-ON device (e.g. Raspberry Pi)

Ruby dependencies:
------------------
(dev on core 2.0.0-p247)

see ./web-services/Gemfile

### Runtime gems:
- cronedit v0.3.0
- sinatra v1.4.4
  - rack v1.5.2
  - tilt v1.4.1
  - rack-protection v1.5.0

### Testing gems:
- rack-test v0.6.2
- test-unit v2.5.5

### Utility gems
- bundler v1.6.2

Once bundler installed, grab all gems with issuing a *bundle install* command from source root directory.

How to install?
---------------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-install%3F

Configuration:
--------------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-configure%3F

How to use:
-----------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-use%3F

API documentation :
-------------------

### Service URLs:
Server port is not configurable atm. Set to **4600**.

## /
Just as a proof that server is alive :)

## /big_brother.json
Returns contents of *big_brother.log* file

**big_brother.json** : {"events":["EVT1", ... , "EVTn"]}

## /control/esxi/status.json
Returns status of hypervisor (uses ping and ssh)

**status.json** : {"status":"STATE"}
- **STATE** :  UP|UP, RUNNING|DOWN

## /control/esxi/on
Turns on hypervisor (uses wakeonlan)

## /control/esxi/off
Turns off hypervisor (uses ssh to connect, then poweroff)

## /control/esxi/schedule/enable/[on_time]/[off_time]
Turns hypervisor on at on_time (00:00 -> 23:59), off at off_time (uses crontab)

## /control/esxi/schedule/disable
Erases scheduled on/off events - *bugged : does not work for now*

## /control/esxi/schedule/status
Returns current schedule if set, or disabled

**status.json** : {"status":{"on_at":"HH:MM","off_at":"HH:MM"}} OR {"status":"disabled"}

## /control/esxi/vms.json
Returns list of hypervisor's virtual machines (uses ssh)

**vms.json** : {"virtualMachines":[VM1, ... , VMn]}
- **VM** : {"id":"ID","name":"NAME","guest_os":"GUEST_OS"}

## /control/esxi/vm/[vm_id]/status.json 
Returns status (ON/OFF) of specified virtual machine (uses ssh)

**status.json** : {"status":"STATE"}
- **STATE** : ON|OFF

## /control/esxi/disks.json
Returns list of hard disks plugged to hypervisor with a few details (uses ssh-esxcli)

(esxi)**disks.json** : {"disks":[DISK1, ... , DISKn]}
- **DISK** : {"id":ID,"tech_id":"TECH_ID","model":"MODEL","revision":"REVISION","size_gigabytes":SIZE,"device":"DEVICE","serial_no":"SERIAL"","port":"PORT"}

## /control/esxi/disk/[disk_id]/smart.json
Returns SMART details of specified hard disk (uses ssh-esxcli)

**smart.json** : {"smart":{"i_status":"STATE","items":[ITEM1 , ... , ITEMn]}}
- **STATE** : OK|KO
- **ITEM** : {"id":ID,"worst":"WORST","value":"VALUE","threshold":"THR","label":"LBL","status":"STATE"}
  - **STATE** : OK|WARN|KO
  
### HTTP status codes (will depend on services)
- **200** : OK, JSON in response body
- **204** : OK, no response body
- **400** : KO, invalid argument specified
- **404** : KO, asked item not found
- **500** : KO, generic system error
- **503** : KO, could not reach ESXI host properly.
