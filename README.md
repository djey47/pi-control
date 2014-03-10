pi-control
==========

Set of web-services to control/monitor ESXi hypervisor from always-ON device (e.g. Raspberry Pi)


Configuration:
--------------
Watch and update ./web-services/conf/pi-control.yml.

You should define hostname and user to access ESXi hypervisor via SSH.

Also, app requires MAC address of hypervisor and LAN broadcast address.


How to use:
-----------
- To start pi-control : ruby ./web-services/rupees/pi_control.rb

- To stop it : kill it !


Enabled services:
-----------------

Requirements:
- Client must have ssh and wakeonlan utilities available
- Target server must be accessible from SSH client on default port (22), without password (public key copied to authorized_keys file).

Service URLs:
- /big_brother.json : display contents of big_brother.log file
- /control/esxi/on : turns on hypervisor (uses wakeonlan)
- /control/esxi/off : turns off hypervisor (uses ssh to connect, then poweroff)



Ruby dependencies:
------------------
(core 2.0.0-p247)

Runtime gems:
- sinatra v1.4.4
  - rack v1.5.2
  - tilt v1.4.1
  - rack-protection v1.5.0

Testing gems:
- test-unit v2.5.5