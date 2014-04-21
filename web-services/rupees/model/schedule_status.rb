#schedule_entry.rb - Represents scheduling status

class ScheduleStatus

  DISABLED = 'disabled'

  attr_reader :on_at
  attr_reader :off_at

  def initialize(on_at, off_at)
    @on_at = on_at
    @off_at = off_at
  end

  def to_json(*a)
    if on_at.nil? or off_at.nil?
      DISABLED.to_json(*a)
    else
      { :on_at => @on_at, :off_at => @off_at }.to_json(*a)
    end
  end
end