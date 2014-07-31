# smart_status_helper.rb - modules to determine per-item and global statuses

require_relative '../../rupees/model/smart_item'

module SMARTStatusHelper

  # Returned by ESXi
  VALUE_NOT_AVAILABLE = 'N/A'
  VALUE_OK = 'OK'
  VALUE_KO = 'KO'

  def self.get_status (label, value, worst, threshold)

    # No information...
    return :UNAVAIL if value == VALUE_NOT_AVAILABLE

    case label
      when ParameterEnum::HEALTH_STATUS
        return :OK if value == VALUE_OK
        return :KO if value == VALUE_KO

      when ParameterEnum::MEDIA_WEAROUT_INDICATOR #TODO usable ?

      when ParameterEnum::WRITE_ERROR_COUNT #Not always handled
      when ParameterEnum::READ_ERROR_COUNT
        return get_error_count_status(value, worst, threshold)

      else
        return :UNAVAIL
    end
  end

  def self.get_global_status(items)
    '<WIP>'
  end

  private
  def self.get_error_count_status(value, worst, threshold)
    v = value.to_i
    t = threshold.to_i
    w = worst.to_i

    return :OK if v > t
    return :KO if v <= t
    #return :WARN if w <= t #FIXME
  end
end