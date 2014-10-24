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
end