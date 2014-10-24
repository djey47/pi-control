#validator_test.rb : Unit Tests

require 'test/unit'

require_relative '../../rupees/utils/validator'

class ValidatorTest < Test::Unit::TestCase 

	def setup
	end

	def test_to_boolean_when_is_not_one_should_raise_argument_error
		#given-when-then
		begin
			Validator::to_boolean?(nil)
			Validator::to_boolean?(0)
			Validator::to_boolean?(1.00)
			Validator::to_boolean?([])
			Validator::to_boolean?({})

			fail 'Should raise ArgumentError'
		rescue => argument_error

		end
	end

	def test_to_boolean_when_is_one_should_return_boolean_values
		#given-when-then
		assert_true(Validator::to_boolean?(true))
		assert_true(Validator::to_boolean?('true'))
		assert_false(Validator::to_boolean?(false))
		assert_false(Validator::to_boolean?('false'))
	end
end