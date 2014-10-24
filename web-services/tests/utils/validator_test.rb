#validator_test.rb : Unit Tests

require 'test/unit'

require_relative '../../rupees/utils/validator'

class ValidatorTest < Test::Unit::TestCase 

	def setup
	end

	def test_to_boolean_when_is_not_one_should_raise_argument_error
		#given-when-then
		begin
			Validator::to_boolean?('faux')

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

	def test_check_tcp_port_when_valid_should_not_raise_argument_error
		#given-when-then
		Validator::check_tcp_port(1)
		Validator::check_tcp_port('1')
		Validator::check_tcp_port(8080)
		Validator::check_tcp_port('8080')
		Validator::check_tcp_port(65535)
		Validator::check_tcp_port('65535')
	end	

	def test_check_tcp_port_when_nan_should_raise_argument_error
		#given-when-then
		begin
			Validator::check_tcp_port?('abc')

			fail 'Should raise ArgumentError'
		rescue => argument_error
		end
	end	

	def test_check_tcp_port_when_number_out_of_range_should_raise_argument_error
		#given-when-then
		begin
			Validator::check_tcp_port?(65536)

			fail 'Should raise ArgumentError'
		rescue => argument_error
		end
	end

	def test_check_directory_path_when_valid_should_not_raise_argument_error
		#given-when-then
		Validator::check_directory_path('dir')
		Validator::check_directory_path('dir/')
		Validator::check_directory_path('/tmp/dir')
		Validator::check_directory_path('./dir')
		Validator::check_directory_path('../dir')
	end		
end