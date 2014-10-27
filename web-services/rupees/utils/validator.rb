# validator.rb - validates values for standard and user defined types

module Validator

	# Converts provided value to boolean or raise ArgumentError if value is not supported
	def self.to_boolean?(value)
    	return true if value == true || value =~ (/^true$/)
    	return false if value == false || value =~ (/^false$/)
    	raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
	end

	# Checks if provided value is valid for TCP port, else will raise ArgumentError
	def self.check_tcp_port(value)
		port = Integer(value)
		raise ArgumentError.new("invalid value for TCP port: \"#{port}\"") unless port.between?(1, 65535)
	end

	# Checks if provided value is designing a valid directory, else will raise ArgumentError.
	# Does not check whether specified directory exists or not.
	def self.check_directory_path(value)
		raise ArgumentError.new("invalid value for directory path: \"#{value}\"") unless value =~ (/^(\/?[^<>:\"\'\/\s|?*]+)+\/?$/)		
	end

	# Checks if provided value is designing a valid MAC address, else will raise ArgumentError.
	def self.check_mac_address(value)
		raise ArgumentError.new("invalid value for MAC address: \"#{value}\"") unless value =~ (/^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i)		
	end	

	# Checks if provided value is designing a valid IP address, else will raise ArgumentError.
	def self.check_ip_address(value)
		raise ArgumentError.new("invalid value for IP address: \"#{value}\"") unless value =~ 
			(/^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}([01]?\d\d?|2[0-4]\d|25[0-5])$/)		
	end
end