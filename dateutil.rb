# encoding: utf-8
require 'time'

class DateUtil
  def self.parse_date(str)
    m = str.match(%r{\A(\d{4})[-/](\d{2})[-/](\d{2}) (\d{2}):(\d{2})(:(\d{2}))?\z})
    if m
      year, month, date, hour, minute = m[1..5].map{|n| n.to_i}
      second = (m[7] || '00').to_i

      if hour >= 24
        hour -= 24
        next_day = true
      else
        next_day = false
      end

      t = Time.local(year, month, date, hour, minute, second)
      if next_day
        t += 24 * 60 * 60
      end
      t
    else
      puts str
      raise
    end
  end
end
