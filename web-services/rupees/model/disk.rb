# disk.rb - represents basic information about one disk.

class Disk

  attr_reader :id
  attr_reader :model
  attr_reader :size_gigabytes
  attr_reader :device
  attr_reader :temperature_celsius
  attr_reader :smart_status
  attr_reader :smartx_status

  def initialize(id = -1, model = 'N/A', size_gigabytes = -1, device = 'N/A', temperature_celsius = -1, smart_status = 'N/A', smartx_status = 'N/A')
    @id = id
    @model = model
    @size_gigabytes = size_gigabytes
    @device = device
    @temperature_celsius = temperature_celsius
    @smart_status = smart_status
    @smartx_status = smartx_status
  end

  def to_json(*a)
    {
        :id => @id,
        :model => @model,
        :size_gigabytes => @size_gigabytes,
        :device => @device,
        :temperature_celsius => @temperature_celsius,
        :smart_status => @smart_status,
        :smartx_status => @smartx_status
    }.to_json(*a)
  end
end