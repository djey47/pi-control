FROM alpine
#ENV http_proxy "http://10.110.20.66:3128"
#ENV https_proxy "https://10.110.20.66:3128"
RUN apk add --update ruby ruby-irb openssl && rm -rf /var/cache/apk/*
#RUN gem sources -r https://rubygems.org/ && gem sources -a http://rubygems.org/
RUN gem update && gem install bundler
RUN wget https://github.com/djey47/pi-control/raw/master/release/pi-control-ruby-20160328.R1.05.tar.gz > /tmp/pi-control.tar.gz
