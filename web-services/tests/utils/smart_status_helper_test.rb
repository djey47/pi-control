# smart_status_helper_test.rb - unit tests for SMARTStatusHelper module

require 'test/unit'
require_relative '../../../web-services/rupees/model/smart_item'
require_relative '../../../web-services/rupees/utils/smart_status_helper'

class SMARTStatusHelperTest < Test::Unit::TestCase

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