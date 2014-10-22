# cache.rb - object cache support (disk list, smart data)

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
    	@logger = Logger.new(STDOUT)
    	@logger.level = Logger::INFO	

    	@disks = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_DISKS_SECS)
    	@smart = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_SMART_SECS)
  	end

  	def clear_all
  		@disks.flush
  		@smart.flush
  	end

  	def fetch_disks_else
  		@logger.info('[Cache][disks] Requesting cache...')

	    @disks.cache(CACHE_KEY_DISKS) do
      		@logger.info('[Cache][disks] Cache miss!')

	      	yield
	    end  		
  	end  	

  	def fetch_smart_else(disk_ids_suffix)
  		@logger.info("[Cache][smart] Requesting cache for suffix #{disk_ids_suffix}...")

	    @smart.cache("#{CACHE_KEY_SMART_PREFIX}#{disk_ids_suffix}") do
      		@logger.info('[Cache][smart] Cache miss!')

	      	yield
	    end  		
  	end

  	def store_smart(disk_id, smart_data)
   		@logger.info("[Cache][smart] Caching data for disk_id #{disk_id}...")
   		
		@smart.set("#{CACHE_KEY_SMART_PREFIX}#{disk_id}", smart_data)   		
  	end
end