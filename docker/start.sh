#! /bin/sh
sed -i "s/{{ESXI_HOST}}/${ESXI_HOST}/" web-services/conf/pi-control.yml \
&& sed -i "s/{{ESXI_USER}}/${ESXI_USER}/" web-services/conf/pi-control.yml \
&& sed -i "s/{{ESXI_MAC_ADDR}}/${ESXI_MAC_ADDR}/" web-services/conf/pi-control.yml \
&& sed -i "s/{{LAN_BROADCAST_ADDR}}/${LAN_BROADCAST_ADDR}/" web-services/conf/pi-control.yml \
&& scripts/start.sh
