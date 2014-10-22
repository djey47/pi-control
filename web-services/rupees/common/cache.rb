# cache.rb - object cache support

require 'diskcached'
require 'singleton'
require_relative 'configuration'

class Cache
	include Singleton

  	#Cache keys (diskcached)
  	CACHE_KEY_DISKS = 'DISKS'
  	CACHE_KEY_SMART_PREFIX = 'SMART_'

  	#Cache parameters
  	CACHE_EXPIRY_DISKS_SECS = 3600
  	CACHE_EXPIRY_SMART_SECS = 30

	attr_reader :disks
  	attr_reader :smart

	def initialize
    	@disks = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_DISKS_SECS)
    	@smart = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_SMART_SECS)
  	end

  	def clear_all
  		@disks.flush
  		@smart.flush
  	end
end