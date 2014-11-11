#! /bin/sh

if [ "$#" -gt 1 ]; then
	echo "Usage: $0 [--check]"
	echo "check: perform install check before starting pi-control."
	exit 1
fi

#Tries to resolve binary given in first arg, and exits with message given in second arg if it fails.
whichBinary () {
	which $1
	if [ "$?" -ne "0" ]; then
		echo $2
		exit 1
	fi	
}

if [ "$1" = "--check" ]; then
	echo "* Performing install check..."
	
	echo "  > Ruby interpreter..."
	whichBinary ruby "! ERROR: ruby script engine not installed, please see http://rvm.io"
	whichBinary gem "! ERROR: ruby gem utility not installed, please see http://rvm.io"
	gem list | grep "bundler"
	if [  "$?" -ne "0" ]; then
		echo "! ERROR: bundler gem not installed, please run 'gem install bundler && bundle install'"
		exit 1
	fi
	
	echo "  > Local commands..."
	whichBinary curl "! ERROR: curl not installed, please run 'apt-get install curl'"
	whichBinary ssh "! ERROR: ssh not installed, please run 'apt-get install ssh'"
	whichBinary wakeonlan "! ERROR: wakeonlan not installed, please run 'apt-get install wakeonlan'"

	echo "* Well Done!"
fi

echo "* Starting pi-control web services..."
ruby ./web-services/rupees/pi_control.rb
exit 0