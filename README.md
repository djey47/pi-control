pi-control
==========

Set of REST web-services to control/monitor ESXi hypervisor from always-ON device (e.g. Raspberry Pi)


How to use:
-----------
- To start pi-control : ruby ./web-services/rupees/pi_control.rb


Enabled services:
-----------------
Target server must be accessed with SSH client on default port (22), without password (public key copied to authorized_keys).

- /control/esxi/off : turns off hypervisor

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