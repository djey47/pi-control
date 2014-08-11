# disk_smart_multi.rb - represents SMART details about two+ disks

require 'json'

class DiskSmartMulti

  attr_reader :disk_id
  attr_reader :disk_smart

  def initialize(disk_id, disk_smart)
    @disk_id = disk_id
    @disk_smart = disk_smart
  end

  def to_json(*a)
    {
        :disk_id => @disk_id,
        :disk_smart => @disk_smart
    }.to_json(*a)
    end
end