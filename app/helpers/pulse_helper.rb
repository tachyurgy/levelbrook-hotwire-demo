module PulseHelper
  # Build an SVG polyline + area path for a sparkline from a list of values.
  # Server-rendered so the broadcast morph just animates the points — no JS
  # charting library. Returns { line:, area:, w:, h: } of path strings.
  def sparkline(points, width: 240, height: 48, pad: 4)
    points = points.map(&:to_f)
    return { line: "", area: "", w: width, h: height } if points.size < 2

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
    { line: line, area: area, w: width, h: height }
  end
end
