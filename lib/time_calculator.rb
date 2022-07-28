module TimeCalculator
  def self.period(from,to)
    # return day period of duration
    ((to.to_time - from.to_time).to_f / 3600 / 24).ceil
  end

  def self.parse_time(time)
    time.present? ? Time.parse(time) : Time.current
  end

  def self.next_day(time)
    time += 86400
  end

  def self.round_down(time, time_level)
    time_level = time_level.to_i
    if time.to_i % time_level != 0
      Time.at((time.to_f / time_level).floor * time_level)
    else
      time
    end
  end
end
