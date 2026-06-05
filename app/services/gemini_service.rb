# Tiny wrapper around the Gemini Generative Language API. Used by Ballot to turn
# a one-line audience question into a set of votable poll options — a live, no-gem
# LLM integration that drives the same broadcasts_refreshes morph as a hand-built
# poll. Uses Ruby's stdlib Net::HTTP (no extra gems) + structured JSON output so
# we never have to parse free-form prose.
require "net/http"
require "json"

module GeminiService
  # API key is read from the environment or Rails credentials only — never
  # hardcoded. Set BALLOT_GEMINI_API_KEY (we deliberately avoid the generic
  # GEMINI_API_KEY name so an unrelated shell var can't shadow it) or store it
  # under credentials at gemini.api_key. When unset, poll_options raises
  # GeminiService::Error and the controller falls back gracefully.
  API_KEY = ENV["BALLOT_GEMINI_API_KEY"].presence ||
    Rails.application.credentials.dig(:gemini, :api_key)

  MODEL = ENV.fetch("GEMINI_MODEL", "gemini-2.5-flash")
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
  STREAM_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%s:streamGenerateContent"

  Error = Class.new(StandardError)

  module_function

  # Whether a live key is configured. Lets the Relay controller fall back to a
  # canned token stream (so the demo still works on a box with no key) while
  # still exercising the real ai_stream protocol encoder end to end.
  def configured?
    API_KEY.present?
  end

  # Stream a Gemini completion token-by-token, yielding each text delta as it
  # arrives. This is the raw token source the Relay app pipes through the
  # ai_stream Writer. Uses Gemini's Server-Sent-Events transport
  # (?alt=sse), parsing each `data: {…}` line for incremental `parts[].text`.
  #
  #   GeminiService.stream_text(prompt: "Explain SSE") { |delta| writer.text_delta(delta, id:) }
  #
  # Raises GeminiService::Error on a non-2xx response or transport failure; the
  # caller decides whether to surface w.error(...) or fall back.
  def stream_text(prompt:, system: nil, temperature: 0.7)
    raise Error, "no Gemini API key configured (set BALLOT_GEMINI_API_KEY)" if API_KEY.blank?

    body = {
      contents: [ { role: "user", parts: [ { text: prompt.to_s } ] } ],
      generationConfig: { temperature: temperature }
    }
    body[:systemInstruction] = { parts: [ { text: system } ] } if system.present?

    uri = URI(format(STREAM_ENDPOINT, MODEL))
    uri.query = URI.encode_www_form(alt: "sse", key: API_KEY)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 60

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = body.to_json

    http.request(req) do |res|
      unless res.is_a?(Net::HTTPSuccess)
        raise Error, "HTTP #{res.code}: #{res.read_body.to_s[0, 300]}"
      end

      buffer = +""
      res.read_body do |chunk|
        buffer << chunk
        while (nl = buffer.index("\n"))
          line = buffer.slice!(0..nl).chomp
          next unless line.start_with?("data:")

          payload = line.delete_prefix("data:").strip
          next if payload.empty? || payload == "[DONE]"

          json = JSON.parse(payload) rescue nil
          next unless json

          json.dig("candidates", 0, "content", "parts")&.each do |part|
            text = part["text"]
            yield text if text && !text.empty?
          end
        end
      end
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise Error, "timeout: #{e.message}"
  end

  # Safe arithmetic evaluator used by the Relay "tool call" preset. Real local
  # computation (no eval, no network) so the tool-output part the UI renders is
  # genuinely the result of executing a tool — exactly the agentic loop the
  # protocol exists to carry. Accepts + - * / ( ) and decimals.
  def calculate(expression)
    expr = expression.to_s
    raise Error, "unsupported characters" unless expr.match?(/\A[\d\s().+\-*\/]+\z/)
    tokens = expr.scan(/\d+\.?\d*|[()+\-*\/]/)
    raise Error, "empty expression" if tokens.empty?

    output = []
    ops = []
    prec = { "+" => 1, "-" => 1, "*" => 2, "/" => 2 }
    apply = lambda do
      op = ops.pop
      b = output.pop
      a = output.pop
      raise Error, "malformed" if a.nil? || b.nil?
      output << case op
                when "+" then a + b
                when "-" then a - b
                when "*" then a * b
                when "/" then (raise Error, "division by zero" if b.zero?); a / b
                end
    end

    tokens.each do |t|
      if t.match?(/\A\d/)
        output << t.to_f
      elsif t == "("
        ops << t
      elsif t == ")"
        apply.call while ops.last && ops.last != "("
        ops.pop
      else
        apply.call while ops.last && ops.last != "(" && prec[ops.last] >= prec[t]
        ops << t
      end
    end
    apply.call while ops.any?
    result = output.first
    raise Error, "malformed" if output.size != 1 || result.nil?

    result == result.to_i ? result.to_i : result.round(6)
  end

  # Given an audience question, return 3–4 concise, mutually-exclusive answer
  # options a room could vote between. Raises GeminiService::Error on failure so
  # the controller can fall back gracefully.
  def poll_options(question:)
    prompt = <<~TXT
      Someone asked this in a live team meeting and we want to turn it into a quick poll:

      "#{question.to_s.strip}"

      Generate 3 or 4 distinct, mutually-exclusive answer options the room can vote
      between. Each option must be short (max ~6 words), specific, and a plausible
      real answer — not "other" or "all of the above". Return only the options.
    TXT

    body = {
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: {
        temperature: 0.9,
        responseMimeType: "application/json",
        responseSchema: {
          type: "object",
          properties: {
            options: {
              type: "array",
              items: { type: "string" },
              minItems: 3,
              maxItems: 4
            }
          },
          required: [ "options" ]
        }
      }
    }

    json = post(body)
    text = json.dig("candidates", 0, "content", "parts", 0, "text")
    raise Error, "empty response: #{json.to_json[0, 300]}" if text.blank?

    options = JSON.parse(text).fetch("options", [])
      .map { |o| o.to_s.strip }
      .reject(&:blank?)
      .first(4)
    raise Error, "no options parsed" if options.empty?

    options
  end

  def post(body)
    raise Error, "no Gemini API key configured (set BALLOT_GEMINI_API_KEY)" if API_KEY.blank?

    uri = URI(format(ENDPOINT, MODEL))
    uri.query = URI.encode_www_form(key: API_KEY)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 20

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = body.to_json

    res = http.request(req)
    raise Error, "HTTP #{res.code}: #{res.body.to_s[0, 300]}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  rescue JSON::ParserError => e
    raise Error, "bad JSON: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise Error, "timeout: #{e.message}"
  end
end
