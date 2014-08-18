#schedule_entry.rb - Represents scheduling status

class ScheduleStatus

  DISABLED = 'disabled'

  attr_reader :on_at
  attr_reader :off_at

  def initialize(on_at = nil, off_at = nil)

    @disabled = (on_at.nil? or off_at.nil?)

    unless @disabled
      @on_at = on_at
      @off_at = off_at
    end    
  end

  def to_json(*a)

    return DISABLED.to_json(*a) if @disabled

    { :on_at => @on_at, :off_at => @off_at }.to_json(*a)
  end

  def disabled?
    
    @disabled
  end
end