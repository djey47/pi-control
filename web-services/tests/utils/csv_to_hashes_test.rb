# csv_to_hashes_test - unit tests

require 'test/unit'
require_relative '../../rupees/utils/csv_to_hashes'

class CSVToHashesTest < Test::Unit::TestCase
  include CSVToHashes

  def test_convert_simple_csv_should_return_hash_array
    #given
    csv = "a,b,c\n1,2,3\n4,5,6"

    #when
    hashes = CSVToHashes.convert(csv)

    #then
    assert_equal(2, hashes.length)
    assert_equal(3, hashes[0].length)
    assert_equal(3, hashes[1].length)
    assert_equal('2', hashes[0]['b'])
    assert_equal('5', hashes[1]['b'])
  end

  def test_convert_invalid_csv_should_return_empty_array
    #given
    csv = 'a,b,c1,2,34,5,6'

    #when
    hashes = CSVToHashes.convert(csv)

    #then
    assert_equal(0, hashes.length)
  end

  def test_convert_empty_csv_should_return_empty_array
    #given
    csv = ''

    #when
    hashes = CSVToHashes.convert(csv)

    #then
    assert_equal(0, hashes.length)
  end
end