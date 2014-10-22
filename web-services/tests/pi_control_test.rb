#pi_control_test.rb : Unit Tests

require 'test/unit'
require_relative '../rupees/common/configuration.rb'
require_relative '../rupees/common/cache.rb'
require_relative 'utils/cache_helper.rb'

class PiControlTest < Test::Unit::TestCase 

	def setup
    	Cache.instance.clear_all
	end

	def test_stop_server_should_clear_all_caches
		omit('Interactive test, server should be interrupted manually, for now')

		#given
		cache_path = "#{Configuration::get.app_cache_directory}/*.cache"
		CacheHelper::populate(cache_path)

		#when
		puts '**'
		puts '** PiControl server will now start - please hit CTRL-C to exit and continue testing!'
		puts '**'
		require_relative '../rupees/pi_control.rb'

		#then
		assert_true(Dir.glob(cache_path).empty?)
	end

end