# Relay — the ai_stream flagship. Renders a live LLM chat whose tokens arrive
# from Google Gemini, encoded on the wire as Vercel-AI-SDK data-stream-protocol
# frames by Levelbrook's `ai_stream` gem (vendored at vendor/gems/ai_stream).
# The page is static; all the streaming happens against MessagesController.
class Relay::ChatController < ApplicationController
  # Curated prompt presets shown as one-tap chips. Each is (label, mode, prompt).
  PRESETS = [
    { label: "Explain SSE",        mode: "text",
      prompt: "Explain how Server-Sent Events let a server push tokens to a browser as they are generated. Keep it to 3 short sentences." },
    { label: "Tool call (math)",   mode: "tool",
      prompt: "What is (47 * 89) + 12? Use the calculator tool." },
    { label: "Ship-it haiku",      mode: "text",
      prompt: "Write a short haiku about shipping software with Ruby on Rails." },
    { label: "Rails vs SPA",       mode: "text",
      prompt: "In 3 crisp bullet points, why might a team stream AI responses from a Rails backend instead of a separate Node service?" }
  ].freeze

  # "What you can build" — concrete applications the same protocol unlocks once a
  # Rails app can speak it. This is the pitch: ai_stream is the missing piece that
  # lets any Ruby backend drive the Vercel AI SDK's useChat / useObject hooks.
  APPLICATIONS = [
    { title: "Streaming chat & copilots", part: "text-delta",
      body: "Token-by-token assistant replies in any product — support, docs, an in-app copilot — driven straight from a Rails controller." },
    { title: "Agentic tool use",          part: "tool-input / tool-output",
      body: "Stream the model's tool calls and your server's results as structured parts, so the UI can render each step of an agent as it runs." },
    { title: "Structured object generation", part: "data-*",
      body: "Power the AI SDK's useObject hook: stream a typed object (a form, a plan, a table) field-by-field as the model fills it in." },
    { title: "RAG with inline citations", part: "source-url / source-document",
      body: "Emit the sources behind each answer as first-class parts the frontend can footnote — retrieval-augmented generation that shows its work." },
    { title: "Reasoning traces",          part: "reasoning-delta",
      body: "Surface the model's thinking in a collapsible panel, separate from the final answer, using dedicated reasoning parts." },
    { title: "Live form autofill",        part: "data-* + text-delta",
      body: "Watch a model populate a multi-field form in real time, each value streaming into its input — no page reloads, no SPA." }
  ].freeze

  def index
    @presets = PRESETS
    @applications = APPLICATIONS
    @live = GeminiService.configured?
  end
end
