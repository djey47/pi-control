# disk_smart.rb - reprsents SMART details about one disk

require 'json'

class DiskSmart

  attr_reader :i_status
  attr_reader :items

  def initialize(i_status=:UNAVAIL, items)
    @i_status = i_status
    @items = items
  end

  def to_json(*a)
    {
        :i_status => @i_status,
        :items => @items
    }.to_json(*a)
  end
end