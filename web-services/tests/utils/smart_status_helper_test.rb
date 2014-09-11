# smart_status_helper_test.rb - unit tests for SMARTStatusHelper module

require 'test/unit'
require_relative '../../../web-services/rupees/model/smart_item'
require_relative '../../../web-services/rupees/utils/smart_status_helper'

class SMARTStatusHelperTest < Test::Unit::TestCase

	def test_get_status_any_item_with_unknown_value
		assert_equal(:UNAVAIL, SMARTStatusHelper.get_status('???', 'N/A', 'N/A', 'N/A'))
	end

	def test_get_status_health_status
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Health Status', 'OK', 'N/A', 'N/A'))
		assert_equal(:KO, SMARTStatusHelper.get_status('Health Status', 'KO', 'N/A', 'N/A'))
		assert_equal(:UNAVAIL, SMARTStatusHelper.get_status('Health Status', '??', 'N/A', 'N/A'))
	end

	def test_get_status_read_error_count_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Read Error Count', '200', '200', '250'))
	end	

	def test_get_status_read_error_count_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Read Error Count', '300', '200', '250'))
		assert_equal(:WARN, SMARTStatusHelper.get_status('Read Error Count', '300', '300', '300'))
	end

	def test_get_status_read_error_count_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Read Error Count', '300', '250', '200'))
	end	

	def test_get_status_write_error_count_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Write Error Count', '300', '250', '200'))
	end	

	def test_get_status_media_wearout_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Media Wearout Indicator', '1', '0', '0'))
	end	

	def test_get_status_media_wearout_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Media Wearout Indicator', '5', '0', '0'))
	end

	def test_get_status_media_wearout_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Media Wearout Indicator', '75', '0', '0'))
	end		

	def test_get_status_power_on_hours_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Power-on Hours', '0', '0', '0'))
	end	

	def test_get_status_power_on_hours_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Power-on Hours', '75', '75', '0'))
	end	

	def test_get_status_power_cycle_count_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Power Cycle Count', '15', '15', '20'))
	end	

	def test_get_status_power_cycle_count_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Power Cycle Count', '25', '15', '20'))
	end

	def test_get_status_power_cycle_count_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Power Cycle Count', '50', '25', '20'))
	end	

	def test_get_status_reallocated_sector_count_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Reallocated Sector Count', '15', '15', '36'))
	end	

	def test_get_status_reallocated_sector_count_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Reallocated Sector Count', '45', '25', '36'))
	end

	def test_get_status_reallocated_sector_count_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Reallocated Sector Count', '50', '40', '36'))
	end		

	def test_get_status_raw_read_error_rate_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Raw Read Error Rate', '5', '5', '6'))
	end	

	def test_get_status_raw_read_error_rate_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Raw Read Error Rate', '10', '6', '6'))
	end

	def test_get_status_raw_read_error_rate_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Raw Read Error Rate', '20', '8', '6'))
	end	

	def test_get_status_drive_temperature_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Drive Temperature', '0', '0', '1'))
	end	

	def test_get_status_drive_temperature_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Drive Temperature', '10', '1', '1'))
	end

	def test_get_status_drive_temperature_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Drive Temperature', '20', '10', '1'))
	end	

	def test_get_status_driver_rated_max_temperature_KO
		#given-when-then
		assert_equal(:KO, SMARTStatusHelper.get_status('Driver Rated Max Temperature', '40', '40', '45'))
	end	

	def test_get_status_driver_rated_max_temperature_WARN
		#given-when-then
		assert_equal(:WARN, SMARTStatusHelper.get_status('Driver Rated Max Temperature', '64', '45', '45'))
	end

	def test_get_status_driver_rated_max_temperature_OK
		#given-when-then
		assert_equal(:OK, SMARTStatusHelper.get_status('Driver Rated Max Temperature', '64', '58', '45'))
	end

	def test_get_global_status_one_item_KO
		#given
		items = []
		items << create_item(:KO)	
		items << create_item(:OK)	
		items << create_item(:WARN)	
		items << create_item(:UNAVAIL)	

		#when
		status = SMARTStatusHelper.get_global_status(items)

		#then
		assert_equal(:KO, status)
	end

	def test_get_global_status_one_item_WARN
		#given
		items = []
		items << create_item(:OK)	
		items << create_item(:WARN)	
		items << create_item(:UNAVAIL)	

		#when
		status = SMARTStatusHelper.get_global_status(items)

		#then
		assert_equal(:WARN, status)
	end	

	def test_get_global_status_one_item_OK
		#given
		items = []
		items << create_item(:UNAVAIL)	
		items << create_item(:OK)	
		items << create_item(:UNAVAIL)	

		#when
		status = SMARTStatusHelper.get_global_status(items)

		#then
		assert_equal(:OK, status)
	end

	def test_get_global_status_all_items_UNAVAIL
		#given
		items = []
		items << create_item(:UNAVAIL)	
		items << create_item(:UNAVAIL)	

		#when
		status = SMARTStatusHelper.get_global_status(items)

		#then
		assert_equal(:UNAVAIL, status)
	end

	private
	def create_item(status)
		SmartItem.new(
          1,
          "ITEM 1",
          "200",
          "180",
          "210",
          status)	
	end
end