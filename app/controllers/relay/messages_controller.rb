# The streaming endpoint behind Relay. A POSTed prompt is answered by writing
# Vercel-AI-SDK data-stream-protocol frames straight to the live response, one
# at a time, as Gemini produces tokens. This is exactly the controller shape the
# `ai_stream` README documents — ActionController::Live + an AiStream::Stream —
# proving the gem works end-to-end against a real LLM in production.
class Relay::MessagesController < ApplicationController
  include ActionController::Live

  # System prompt that keeps demo answers tight (this runs on a public site).
  SYSTEM = "You are a knowledgeable assistant embedded in an engineering demo that " \
           "showcases token-by-token streaming. Answer directly and substantively. " \
           "Prefer a few short paragraphs or a tight bulleted list; aim for 120–220 " \
           "words so the streaming is visible, and never exceed ~300 words."

  def create
    prompt = params[:prompt].to_s.strip
    mode   = params[:mode].to_s.presence || "text"
    prompt = "Say hello and invite me to ask anything." if prompt.empty?

    # Required headers: the AI-SDK marker + SSE content type. X-Accel-Buffering
    # disables proxy buffering so frames flush immediately through kamal-proxy.
    AiStream::HEADERS.each { |k, v| response.headers[k] = v }
    response.headers["Content-Type"]     = "text/event-stream"
    response.headers["Cache-Control"]    = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    stream = AiStream::Stream.new do |w|
      w.start
      begin
        mode == "tool" ? run_tool(w, prompt) : run_text(w, prompt)
      rescue GeminiService::Error => e
        Rails.logger.warn("[relay] gemini error: #{e.message}")
        w.error("The model stream failed: #{e.message}")
      end
      w.finish
    end

    stream.each { |frame| response.stream.write(frame) }
  rescue ActionController::Live::ClientDisconnected, IOError
    # Client navigated away mid-stream — nothing to clean up.
  ensure
    response.stream.close
  end

  private

  # Plain streaming completion: pipe each Gemini token through a text part. When
  # no key is configured we fall back to a canned token stream so the protocol
  # path still demonstrates end-to-end (every frame is real ai_stream output).
  def run_text(w, prompt)
    id = w.text_start

    if GeminiService.configured?
      GeminiService.stream_text(prompt: prompt, system: SYSTEM) do |delta|
        emit_smoothly(delta) { |piece| w.text_delta(piece, id: id) }
      end
    else
      canned_text.each_char.each_slice(3) do |chars|
        w.text_delta(chars.join, id: id)
        sleep 0.02
      end
    end

    w.text_end(id: id)

    # Demonstrate a custom data part: stream follow-up suggestions the UI renders
    # as tappable chips (this is how you'd drive the AI SDK's data-* channel).
    w.data("suggestions", { items: [ "Show me the raw protocol", "Try a tool call", "What can I build with this?" ] })
  end

  # Agentic path: the model "calls" a calculator tool, we execute it locally
  # (real arithmetic, no eval), stream the input + output as structured tool
  # parts, then stream a one-line natural-language summary. This shows the
  # protocol carrying more than text — the whole point of useChat tool support.
  def run_tool(w, prompt)
    expr = prompt[/[\d(][\d\s().+\-*\/]*[\d)]/]&.strip || "(47 * 89) + 12"
    tool_id = AiStream::Writer.generate_id

    w.start_step
    w.tool_input_start(tool_call_id: tool_id, tool_name: "calculator")
    # Stream the tool arguments as they would arrive from a function-calling model.
    %Q({"expression":"#{expr}"}).each_char.each_slice(5) do |chars|
      w.tool_input_delta(tool_call_id: tool_id, delta: chars.join)
      sleep 0.02
    end
    w.tool_input_available(tool_call_id: tool_id, tool_name: "calculator", input: { expression: expr })

    result = begin
      GeminiService.calculate(expr)
    rescue GeminiService::Error => e
      "error: #{e.message}"
    end
    w.tool_output_available(tool_call_id: tool_id, output: { expression: expr, result: result })
    w.finish_step

    # Second step: the assistant's spoken answer, informed by the tool result.
    w.start_step
    id = w.text_start
    summary = "The calculator tool returned #{expr} = #{result}. "
    if GeminiService.configured?
      GeminiService.stream_text(
        prompt: "A calculator tool computed #{expr} = #{result}. In one short, friendly sentence, tell the user the result.",
        system: SYSTEM, temperature: 0.4
      ) { |delta| emit_smoothly(delta) { |piece| w.text_delta(piece, id: id) } }
    else
      "#{summary}Tool calls stream as structured parts the UI can render.".each_char.each_slice(3) do |chars|
        w.text_delta(chars.join, id: id)
        sleep 0.02
      end
    end
    w.text_end(id: id)
    w.finish_step
  end

  # Gemini batches its output into a handful of large chunks, so a 4-sentence
  # answer arrives as ~3 deltas and "streaming" reads as a couple of instant
  # jumps. Re-emit each chunk word-by-word with a tiny pause so the UI actually
  # animates token-by-token — the entire point of this demo. Whitespace is
  # preserved exactly (split keeps the separators), so the text reconstructs 1:1.
  def emit_smoothly(text)
    text.to_s.split(/(\s+)/).each do |piece|
      next if piece.empty?
      yield piece
      sleep 0.018 unless piece.match?(/\A\s+\z/)
    end
  end

  def canned_text
    "Hi! No live model key is set on this box, so these tokens are canned — " \
    "but every frame you see in the inspector is real ai_stream protocol output, " \
    "encoded exactly as the Vercel AI SDK expects. Wire up a key and the same " \
    "code path streams a live Gemini response."
  end
end
