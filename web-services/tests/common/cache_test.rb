 #cache_test.rb - Unit Tests

require 'test/unit'
require_relative '../../rupees/common/cache.rb'

class CacheTest < Test::Unit::TestCase 

	def setup
    	Cache.instance.clear_all
  	end

	def test_initialize_should_instantiate_caches
		assert_false(Cache.instance.disks.nil?)
		assert_false(Cache.instance.smart.nil?)
	end

	def test_clear_all_should_remove_all_files
		#given
		cache_path = "#{Configuration::get.app_cache_directory}/*.cache"

	    Cache.instance.fetch_disks_else do
	      []
	    end
	    for i in 1..10 do
		    Cache.instance.smart.cache("#{Cache::CACHE_KEY_SMART_PREFIX}#{i}") do
		      []
		    end
		end
		assert_false(Dir.glob(cache_path).empty?)

		#when
		Cache.instance.clear_all

		#then
		assert_true(Dir.glob(cache_path).empty?)
	end
end