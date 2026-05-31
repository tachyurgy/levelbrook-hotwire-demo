module PulseHelper
  # Build an SVG polyline + area path for a sparkline from a list of values.
  # Server-rendered so the broadcast just swaps the points — no JS charting
  # library. Returns { line:, area:, w:, h:, min:, max: } of path strings.
  def sparkline(points, width: 240, height: 48, pad: 4)
    points = points.map(&:to_f)
    return { line: "", area: "", w: width, h: height, min: 0, max: 0 } if points.size < 2

    min = points.min
    max = points.max
    span = (max - min).zero? ? 1.0 : (max - min)
    step = (width - pad * 2) / (points.size - 1).to_f

    coords = points.each_with_index.map do |v, i|
      x = pad + i * step
      y = (height - pad) - ((v - min) / span) * (height - pad * 2)
      [ x.round(1), y.round(1) ]
    end

    line = coords.map { |x, y| "#{x},#{y}" }.join(" ")
    area = "#{coords.first[0]},#{height - pad} " + line + " #{coords.last[0]},#{height - pad}"
    { line: line, area: area, w: width, h: height, min: min, max: max }
  end

  # The golden-signals time-series chart. Pulls one numeric key out of the rolling
  # timeline and returns everything a server-rendered SVG needs: the area + line
  # paths, the y-extent (for axis labels), evenly spaced gridline y-positions, and
  # the (x, y) of the latest point so the view can pin a "now" marker on the edge.
  def pulse_timeseries(series, key, width: 760, height: 220, pad_x: 0, pad_y: 14, rows: 4)
    values = series.map { |p| p[key].to_f }
    return { line: "", area: "", min: 0, max: 0, grid: [], last: nil, w: width, h: height } if values.size < 2

    min = values.min
    max = values.max
    headroom = (max - min).zero? ? (max.abs.zero? ? 1.0 : max.abs * 0.1) : (max - min) * 0.12
    lo = [ min - headroom, 0.0 ].max
    hi = max + headroom
    span = (hi - lo).zero? ? 1.0 : (hi - lo)
    step = (width - pad_x * 2) / (values.size - 1).to_f

    coords = values.each_with_index.map do |v, i|
      x = pad_x + i * step
      y = (height - pad_y) - ((v - lo) / span) * (height - pad_y * 2)
      [ x.round(1), y.round(1) ]
    end

    line = coords.map { |x, y| "#{x},#{y}" }.join(" ")
    area = "#{coords.first[0]},#{height} " + line + " #{coords.last[0]},#{height}"

    grid = (0..rows).map do |r|
      frac = r / rows.to_f
      { y: (pad_y + frac * (height - pad_y * 2)).round(1), value: (hi - frac * span) }
    end

    { line: line, area: area, min: lo, max: hi, grid: grid, last: coords.last, w: width, h: height }
  end

  # Format a metric value for axis / tile display.
  def pulse_num(value, key)
    case key
    when :tp    then number_with_delimiter(value.round)
    when :lat   then "#{value.round}ms"
    when :err   then "#{value.round(1)}%"
    when :apdex then format("%.2f", value)
    else value.round.to_s
    end
  end

  # A small up/down delta chip comparing the last two timeline points.
  def pulse_delta(series, key, invert: false)
    return nil if series.size < 2

    cur  = series[-1][key].to_f
    prev = series[-2][key].to_f
    return { dir: :flat, good: true, text: "0.0%" } if prev.zero?

    pct = ((cur - prev) / prev.abs) * 100
    dir = pct.abs < 0.05 ? :flat : (pct.positive? ? :up : :down)
    good = invert ? (dir == :down) : (dir == :up)
    { dir: dir, good: good, text: "#{pct.negative? ? '−' : '+'}#{format('%.1f', pct.abs)}%" }
  end

  EVENT_LEVEL = {
    "error" => { dot: "#c8402f", text: "text-rose-600" },
    "warn"  => { dot: "#d97706", text: "text-amber-600" },
    "info"  => { dot: "#10b981", text: "text-[var(--color-ink-soft)]" }
  }.freeze

  def pulse_event_style(level) = EVENT_LEVEL.fetch(level, EVENT_LEVEL["info"])
end
