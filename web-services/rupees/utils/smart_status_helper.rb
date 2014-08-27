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
        return get_health_status_status(value, worst, threshold)

      when ParameterEnum::MEDIA_WEAROUT_INDICATOR #TODO usable ?
        return :UNAVAIL

      when ParameterEnum::WRITE_ERROR_COUNT
        return get_error_count_status(value, worst, threshold)
        
      when ParameterEnum::READ_ERROR_COUNT
        return get_error_count_status(value, worst, threshold)

      else
        return :UNAVAIL
    end
  end

  def self.get_global_status(items)
    return :KO if(at_least_one?(:KO, items))

    return :WARN if(at_least_one?(:WARN, items))

    return :OK if(at_least_one?(:OK, items))

    :UNAVAIL
  end

  private
  def self.get_error_count_status(value, worst, threshold)
    v = value.to_i
    t = threshold.to_i
    w = worst.to_i

    return :KO if v < t
    return :WARN if w <= t
    return :OK if v > t
  end

  def self.get_health_status_status(value, worst, threshold)
      return :OK if value == VALUE_OK
      return :KO if value == VALUE_KO
      return :UNAVAIL
  end

  def self.at_least_one?(status, items)
    items.each do |item|
      return true if item.status == status 
    end

    false
  end
end