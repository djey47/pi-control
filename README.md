pi-control
==========

[![Build Status](https://travis-ci.org/djey47/pi-control.svg?branch=master)](https://travis-ci.org/djey47/pi-control)

Set of web-services to control/monitor ESXi hypervisor from a linux-based, always-ON device (e.g. Raspberry Pi).

Featuring [complete API](https://github.com/djey47/pi-control/wiki/API-reference): 
- hypervisor ON/OFF switch + schedule + status
- hard disk list
- SMART details of particular disk(s)
- virtual machine list
- virtual machine ON/OFF switch + status
- global logging to watch all received service requests (big brother).

Monitoring usage example from web client can be found at following project : [smartX](https://github.com/djey47/smartX)

Ruby dependencies:
------------------
(dev on core 2.0.0-p247)

see **./web-services/Gemfile**

### Runtime gems:
- cronedit v0.3.0
- diskcached v1.1.0
- json v1.8.3
- sinatra v1.4.4
  - rack v1.5.2
  - tilt v1.4.1
  - rack-protection v1.5.0

### Testing gems:
- rack-test v0.6.2
- test-unit v2.5.5

### Utility gems
- bundler v1.6.2

How to install, configure and use?
----------------------------------

Please have a look at:
- [installing](https://github.com/djey47/pi-control/wiki/How-to-install%3F)
- [configuring](https://github.com/djey47/pi-control/wiki/How-to-configure%3F)
- [using](https://github.com/djey47/pi-control/wiki/How-to-use%3F)
