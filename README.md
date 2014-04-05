pi-control
==========

Set of web-services to control/monitor ESXi hypervisor from a linux-based, always-ON device (e.g. Raspberry Pi)


Configuration:
--------------
Watch and update *./web-services/conf/pi-control.yml*:

- Set app/is-production flag to false when developing, true when running on a server (allowing access from other machines).

- Define esxi/hostname and esxi/user params for app to access ESXi hypervisor via SSH.

- Also requires MAC address of hypervisor (esxi/mac-address) and LAN broadcast address (lan/broadcast-adress).


How to use:
-----------
- To start pi-control : **ruby ./web-services/rupees/pi_control.rb**

- To stop it : kill it !


Enabled services:
-----------------

### Requirements:
- Client must have *ssh* and *wakeonlan* utilities available
- Target server must be accessible from SSH client on default port (22), without password (public key copied to *authorized_keys* file).
- Target server IP must be in *known_hosts* files on source ! Otherwise esxi/off command will fail. To do this, use *ssh* to once connect target server manually.

### Service URLs:
- **/big_brother.json** : returns contents of *big_brother.log* file
- **/control/esxi/on** : turns on hypervisor (uses wakeonlan)
- **/control/esxi/off** : turns off hypervisor (uses ssh to connect, then poweroff)
- **/control/esxi/vms.json** : returns list of hypervisor's virtual machines
- **/control/esxi/vm/[vm_id]/status.json** : returns status (ON/OFF) of specified virtual machine


Ruby dependencies:
------------------
(dev on core 2.0.0-p247)

### Runtime gems:
- sinatra v1.4.4
  - rack v1.5.2
  - tilt v1.4.1
  - rack-protection v1.5.0

### Testing gems:
- test-unit v2.5.5
