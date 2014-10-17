# disk.rb - represents basic information about one disk.

class Disk

  attr_reader :id
  attr_reader :tech_id
  attr_reader :model
  attr_reader :revision
  attr_reader :size_gigabytes
  attr_reader :device
  attr_reader :serial_no

  def initialize(id = -1, tech_id = 'N/A', model = 'N/A', revision = 'N/A', size_gigabytes = -1, device = 'N/A', serial_no = 'N/A')
    @id = id
    @tech_id = tech_id
    @model = model
    @revision = revision
    @size_gigabytes = size_gigabytes
    @device = device
    @serial_no = serial_no
  end

  def to_json(*a)
    {
        :id => @id,
        :tech_id => @tech_id,
        :model => @model,
        :revision => @revision,
        :size_gigabytes => @size_gigabytes,
        :device => @device,
        :serial_no => @serial_no
    }.to_json(*a)
  end
end