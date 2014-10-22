 #cache_test.rb - Unit Tests

require 'test/unit'
require_relative '../../rupees/common/cache.rb'
require_relative '../utils/cache_helper.rb'

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
		CacheHelper::populate(cache_path)

		#when
		Cache.instance.clear_all

		#then
		assert_true(Dir.glob(cache_path).empty?)
	end
end