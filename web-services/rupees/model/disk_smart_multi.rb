# disk_smart_multi.rb - represents SMART details about two+ disks

require 'json'

class DiskSmartMulti

  attr_reader :disk_id
  attr_reader :smart

  def initialize(disk_id, smart)
    @disk_id = disk_id
    @smart = smart
  end

  def to_json(*a)
    {
        :disk_id => @disk_id,
        :smart => @smart
    }.to_json(*a)
    end
end