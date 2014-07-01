pi-control
==========

Set of web-services to control/monitor ESXi hypervisor from a linux-based, always-ON device (e.g. Raspberry Pi).

Features : ON/OFF, status, virtual machine list, hard disk list, SMART details of particular disk, etc...

Monitoring usage example from web client can be found at following project : [smartX](https://github.com/djey47/smartX)

Ruby dependencies:
------------------
(dev on core 2.0.0-p247)

see **./web-services/Gemfile**

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

How to install?
---------------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-install%3F

Configuration:
--------------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-configure%3F

How to use:
-----------

Please have a look at wiki: https://github.com/djey47/pi-control/wiki/How-to-use%3F
