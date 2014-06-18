pi-control
==========

Set of web-services to control/monitor ESXi hypervisor from a linux-based, always-ON device (e.g. Raspberry Pi)


Ruby dependencies:
------------------
(dev on core 2.0.0-p247)

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


Configuration:
--------------
Please watch and update *./web-services/conf/pi-control.yml* accordingly:

- Set app/is-production flag to false when developing, true when running on a server (allowing access from other machines).

- Define esxi/hostname and esxi/user params for app to access ESXi hypervisor via SSH.

- Also requires MAC address of hypervisor (esxi/mac-address) and LAN broadcast address (lan/broadcast-adress).


How to use:
-----------
**Important : set current directory to app root else it won't be able to read config file**

- To execute tests : use provided script: **./scripts/test.sh**

- To start web-services : use provided script : **./scripts/start.sh**

- To stop it : kill it !


Enabled services:
-----------------

### Requirements:
- Hypervisor should be VMWare ESXi 5.5 (may work under 5.1 but untested)
- Client must have *ssh* and *wakeonlan* utilities available
- Target server must be accessible from SSH client on default port (22), without password (public key copied to *authorized_keys* file).
- Target server IP must be in *known_hosts* files on source ! Otherwise esxi/off command will fail. To do this, use *ssh* to once connect target server manually.

### Service URLs:
Server port is not configurable atm. Set to **4600**.

- **/** : just as a proof that server is alive :)
- **/big_brother.json** : returns contents of *big_brother.log* file
- **/control/esxi/status.json** : returns status (UP/UP, RUNNING/DOWN) of hypervisor (uses ping and ssh)
- **/control/esxi/on** : turns on hypervisor (uses wakeonlan)
- **/control/esxi/off** : turns off hypervisor (uses ssh to connect, then poweroff)
- **/control/esxi/schedule/enable/[on_time]/[off_time]** : turns hypervisor on at on_time (00:00 -> 23:59), off at off_time. Uses crontab.
- **/control/esxi/schedule/disable** : erases scheduled on/off events - *bugged : does not work for now*
- **/control/esxi/schedule/status** : returns current schedule if set, or disabled
- **/control/esxi/vms.json** : returns list of hypervisor's virtual machines (uses ssh)
- **/control/esxi/vm/[vm_id]/status.json** : returns status (ON/OFF) of specified virtual machine (uses ssh)
- **/control/esxi/disks.json** : returns list of hard disks plugged to hypervisor with a few details (uses ssh-esxcli)
- **/control/esxi/disk/[disk_id]/smart.json** : returns SMART details of specified hard disk (uses ssh-esxcli)


API details:
------------

### HTTP status codes (will depend on services)
- **200** : OK, JSON in response body
- **204** : OK, no response body
- **400** : KO, invalid argument specified
- **404** : KO, asked item not found
- **500** : KO, generic system error
- **503** : KO, could not reach ESXI host properly.
