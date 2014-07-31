# smart-item.rb - Represents 1 SMART info item.

require 'json'

class SmartItem

  attr_reader :id
  attr_reader :label
  attr_reader :status
  attr_reader :threshold
  attr_reader :value
  attr_reader :worst

  def initialize(id=-1, label='', value=-1, worst=-1, threshold=-1, status=:UNAVAIL)
    @id = id
    @label = label
    @value = value
    @worst = worst
    @threshold = threshold
    @status = status
  end

  def to_json(*a)
    {
        :id => @id,
        :worst => @worst,
        :value => @value,
        :threshold => @threshold,
        :label => @label,
        :status => @status
    }.to_json(*a)
  end
end

# Enumerates all ESXI's SMART items
module ParameterEnum
  HEALTH_STATUS = 'Health Status'

  MEDIA_WEAROUT_INDICATOR = 'Media Wearout Indicator'

  WRITE_ERROR_COUNT = 'Write Error Count'

  READ_ERROR_COUNT = 'Read Error Count'

  POWER_ON_HOURS = 'Power-on Hours'

  POWER_CYCLE_COUNT = 'Power Cycle Count'

  REALLOCATED_SECTOR_COUNT = 'Reallocated Sector Count'

  RAW_READ_ERROR_RATE = 'Raw Read Error Rate'

  DRIVE_TEMPERATURE = 'Drive Temperature'

  DRIVER_RATED_MAX_TEMPERATURE = 'Driver Rated Max Temperature'

  WRITE_SECTORS_TOT_COUNT = 'Write Sectors TOT Count'

  READ_SECTORS_TOT_COUNT = 'Read Sectors TOT Count'

  INITIAL_BAD_BLOCK_COUNT = 'Initial Bad Block Count'
end