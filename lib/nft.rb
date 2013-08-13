

module MeasurementUtils

  XAXIS_FACTORS = {
    "ms" => 1000,
    "s" => 1,
    "min" => 1.0/60.0,
    "h" => 1.0/60.0/60.0
  }.freeze

  def format_value(v, significant=3)
    s = sprintf("%.#{significant}f",v.to_f)
    (pre,post) = s.split('.')
    after = significant - pre.size
    if after > 0
      "#{pre}.#{post[0,after]}"
    else
      pre
    end
  end

  def calculate_outline(s, interval)
    o = MeasurementOutline.new
    total = 0
    values = []
    s.each do |v|
      val = v['value'].try(:to_f)
      o.minval = unless o.minval.nil? then [o.minval, val].min else val end
      o.maxval = unless o.maxval.nil? then [o.maxval, val].max else val end
      total += val
      values << val
    end
    o.avgval = total.to_f / values.size
    values.sort!
    size = values.size
    if size > 0 && (size % 2) == 0
      o.median = (values[size/2] + values[size/2-1])/2.0
    else
      o.median = values[size/2]
    end

    if interval
      # Time span from intervals (only ms used, thus dividing to get seconds)
      timespan = (s.length-1) * interval.to_f / 1000
    else
      # Time span of measurement series in seconds
      last = Time.parse(s[s.length-1]['timestamp'])
      first = Time.parse(s[0]['timestamp'])
      timespan = last - first
    end

    if timespan < 10
      # 0 - 9999 ms
      o.interval_unit = "ms"
    elsif timespan < 10000
      # 0 - 9999 s
      o.interval_unit = "s"
    elsif timespan < 600000
      # 0 - 9999 min
      o.interval_unit = "min"
    else
      o.interval_unit = "h"
    end
    o
  end

  def shorten_series(s, maxsize)
    if s.size <= maxsize
      values = s
    else
      values = []
      ratio = maxsize.to_f / s.size
      c = 1.0
      s.each do |v|
        if c >= 1.0
          values << v
          c -= 1.0
        end
        c += ratio
      end
      values
    end
  end

  def shortened_indices(size, maxsize)
    indices = (0..size-1)
    if size <= maxsize
      indices
    else
      ratio = maxsize.to_f / size
      c = 1.0
      indices.select do
        filter = if c >= 1.0
          c -= 1.0
          true
        else
          false
        end
        c += ratio
        filter
      end
    end
  end

  def series_json(s, maxsize=40)
    s = shorten_series(s, maxsize)
    json = "[" + s.map{|v| shorten_value(v)}.join(",") + "]"
    if json.length >= 255
      new_max = maxsize*255/json.length
      series_json(s, new_max-1)
    else
      json
    end
  end

  def series_json_withx(m, interval_unit, maxsize=200)
    s = m.element_children
    indices = shortened_indices(s.size, maxsize)
    xaxis = get_x_axis(m['interval'], interval_unit, s)
    "[" + indices.map{|i| "[#{xaxis[i]},#{s[i]['value']}]"}.join(",") + "]"
  end

  def group_json_withx(series, group, interval_unit, maxsize=200)
    validate_series(series, group)

    # Create an X axis that will contain all values aligned. For interval
    # based this just means that get the axis from the series with most
    # measurements (since interval unit and interval must be the same). For
    # timestamp based series this means finding the earliest timestamp and
    # calculating X axis values for all measurements against that.
    # Also map the measurements of series to a hash that can be indexed with
    # values from the xaxis array, i.e. set the hash key to the "timestamp"
    # of the particular measurement
    factor   = XAXIS_FACTORS[interval_unit]
    interval = series.first['interval']
    if interval
      xaxis = get_x_axis(interval,
                         interval_unit,
                         get_longest_series(series).element_children)

      mapped_series = series.map do |s|
        mapped = { series: s, measurements: {} }
        s.element_children.each_with_index do |m, i|
          timestamp = get_interval_xaxis_value(factor, interval, i)
          mapped[:measurements][timestamp] = m
        end
        mapped
      end

    else
      earliest = series.map do |s|
        s.element_children.sort_by {|m| Time.parse(m['timestamp'])} .first
      end .sort_by {|m| Time.parse(m['timestamp'])} .first

      xaxis = series.map do |s|
        get_timestamp_xaxis(factor, earliest, s.element_children)
      end .flatten .sort .uniq

      mapped_series = series.map do |s|
        mapped = { series: s, measurements: {} }
        s.element_children.each do |m|
          timestamp = get_timestamp_xaxis_value(factor, earliest, m)
          # TODO (maybe): If there are more than one value with the same timestamp,
          # only one will survive. This is probably not a problem because we
          # may end up leaving out measurements anyway due to shortened index
          mapped[:measurements][timestamp] = m
        end
        mapped
      end
    end

    # Use the xaxis for getting the shortened indices. It is possible that the
    # outcome will not contain any data points from some of the series due to
    # dropping indices (if more than maxsize measurements) but that's quite unlikely
    indices = shortened_indices(xaxis.size, maxsize)

    # Collect the data for the "series" field of the resulting json
    json_series = mapped_series.map do |s|
      "{\"unit\": \"#{s[:series]['unit']}\", \"name\": \"#{s[:series]['name']}\"}"
    end .join(",")

    data = indices.map do |i|
      # Index the xaxis with these indices, and the mapped_series with the xaxis
      # values from the indices.
      ts = xaxis[i]
      values = mapped_series.map do |s|
        if s[:measurements][ts].blank?
          "null"
        else
          s[:measurements][ts]['value']
        end
      end .join(",")
      "[#{ts},#{values}]"
    end .join(",")

    "{\"series\": [#{json_series}], \"interval_unit\": \"#{interval_unit||'null'}\", \"data\": [#{data}]}"
  end

  def shorten_value(v)
    s = v['value']
    s = s[0..-3] if s.end_with? ".0"
    s2 = sprintf("%.1e", v['value'])
    if s2.length < s.length
      s2
    else
      s
    end
  end

  def get_x_axis(interval, interval_unit, s)
    factor = XAXIS_FACTORS[interval_unit]
    if interval
      # Dividing since interval is currently always in milliseconds and
      # the factors are for seconds
      xaxis = (0..s.size-1).map {|i| get_interval_xaxis_value(factor, interval, i)}
    else
      xaxis = get_timestamp_xaxis(factor, s[0], s)
    end
    xaxis
  end

  def get_timestamp_xaxis(factor, ref, s)
    (0..s.size-1).map {|i| get_timestamp_xaxis_value(factor, ref, s[i]) }
  end

  # Get the X axis value of given measurement
  def get_timestamp_xaxis_value(factor, ref, measurement)
    ((Time.parse(measurement['timestamp'])-Time.parse(ref['timestamp']))*factor).to_i
  end

  # Get the X axis value for a interval series measurement
  def get_interval_xaxis_value(factor, interval, index)
    index * interval.to_f * factor / 1000
  end

  # Basic validation of the series in a group
  def validate_series(series, group)
    intervals    = 0
    timestamps   = 0
    intervals_ok = true

    series.each do |s|
      if s['interval']
        intervals += 1
        if s['interval'] != series.first['interval'] || s['interval_unit'] != series.first['interval_unit']
          intervals_ok = false
        end
      else
        timestamps += 1
      end
    end

    if intervals != 0 && timestamps != 0
      raise Nokogiri::XML::SyntaxError.new("Invalid series group #{group}: both interval and non-interval series grouped.")
    end

    unless intervals_ok
      raise Nokogiri::XML::SyntaxError.new("Invalid series group #{group}: not all series use the same interval")
    end
  end

  def get_longest_series(series)
    l = series.first
    # For interval series get the one with most elements
    # TODO: Can we enable unmatching series using timestamps?
    if l['interval']
      series.each do |s|
        if s.element_children.count > l.element_children.count
          l = s
        end
      end
    end
    l
  end
end

class MeasurementOutline
  attr_accessor :minval, :maxval, :avgval, :median, :interval_unit
end
