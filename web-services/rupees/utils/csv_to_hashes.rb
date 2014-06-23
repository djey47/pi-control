# csv_to_hashes.rb - module to convert contents of a CSV String with headers into array of hashes
# e.g  "a,b,c\n1,2,3\n4,5,6" => [[{a => 1}, {b => 2}, {c => 3}], [{a => 4}, {b => 5}, {c => 6}]]

require 'csv'

module CSVToHashes

  def self.convert(csv)

    lines = CSV.parse(csv)
    hashes = []

    if lines.length > 0
      headers = lines[0]

      (1..lines.length-1).each { |i|
        hash = {}

        lines[i].each_with_index { |value, index|
          hash.merge!({headers[index] => value }) unless headers[index].nil?
        }

        hashes << hash
      }
    end

    hashes
  end

end