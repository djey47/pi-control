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