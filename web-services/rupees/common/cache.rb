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

	attr_reader :disks_cache
  	attr_reader :smart_cache

	def initialize
    	@disks_cache = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_DISKS_SECS)
    	@smart_cache = Diskcached.new(Configuration::get.app_cache_directory, CACHE_EXPIRY_SMART_SECS)
  	end

  	def clear_all
    	Dir.glob("#{Configuration::get.app_cache_directory}/*.cache").each { |f| File.delete(f) rescue nil}
  	end
end