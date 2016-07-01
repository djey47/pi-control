FROM alpine
LABEL multi.description="Image running Pi-Control services" \
multi.version="1.0"
ENV http_proxy "http://10.110.20.66:3128"
ENV https_proxy "https://10.110.20.66:3128"

RUN apk add --update ruby ruby-irb openssl ruby-bundler curl && rm -rf /var/cache/apk/*

#RUN curl https://github.com/djey47/pi-control/raw/master/release/pi-control-ruby-20160328.R1.05.tar.gz > /tmp/pi-control.tar.gz

RUN mkdir -p /opt/pi-control

#RUN tar xzf /tmp/pi-control.tar.gz -C /opt/pi-control \
#&& rm /tmp/pi-control.tar.gz

ADD ./pi-control /opt/pi-control

WORKDIR /opt/pi-control
RUN cd web-services && bundle install && cd -
CMD ["./scripts/start.sh"]