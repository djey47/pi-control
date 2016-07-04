FROM resin/rpi-raspbian:jessie-20160622
LABEL multi.description="Image running Pi-Control services on rPi" \
multi.version="1.0"
EXPOSE 4601

RUN apt update 
RUN apt install ruby bundler
RUN apt install curl ssh wakeonlan
RUN apt-get clean && apt-get autoclean

RUN curl -L https://github.com/djey47/pi-control/raw/master/release/pi-control-ruby-20160328.R1.05.tar.gz > /tmp/pi-control.tar.gz

RUN mkdir -p /opt/pi-control

RUN tar xzf /tmp/pi-control.tar.gz -C /opt/pi-control && rm /tmp/pi-control.tar.gz

ADD ./pi-control.yml /opt/pi-control/

WORKDIR /opt/pi-control
RUN cd web-services && bundle install && cd -
CMD ["./scripts/start.sh"]
