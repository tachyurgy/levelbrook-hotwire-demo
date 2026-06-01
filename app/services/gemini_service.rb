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

  Error = Class.new(StandardError)

  module_function

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
