# caching_helper.rb - module to provide utility methods to test with caches

module CachingHelper

  def self.clear_caches
    File::delete("#{Configuration::get.app_cache_directory}/#{Services::CACHE_KEY_DISKS}.cache") rescue nil
    File::delete("#{Configuration::get.app_cache_directory}/#{Services::CACHE_KEY_SMART_PREFIX}1.cache") rescue nil
    File::delete("#{Configuration::get.app_cache_directory}/#{Services::CACHE_KEY_SMART_PREFIX}2.cache") rescue nil
    File::delete("#{Configuration::get.app_cache_directory}/#{Services::CACHE_KEY_SMART_PREFIX}1-2.cache") rescue nil
  end
end