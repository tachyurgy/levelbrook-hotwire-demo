import { Controller } from "@hotwired/stimulus"

// Relay's client. POSTs a prompt to the ActionController::Live endpoint and
// reads the streamed response — which is the Vercel AI SDK data-stream protocol,
// encoded server-side by the ai_stream gem. We parse each `data: {…}` SSE frame
// and (a) render the assistant's answer token-by-token, (b) render tool-call
// cards, and (c) mirror every raw frame into a live "wire inspector" so viewers
// can literally watch the protocol that drives useChat / useObject.
export default class extends Controller {
  static targets = ["input", "transcript", "wire", "suggestions", "send", "empty"]
  static values = { url: String }

  submit(event) {
    event.preventDefault()
    const prompt = this.inputTarget.value.trim()
    if (prompt) this.send(prompt, "text")
  }

  preset(event) {
    const { prompt, mode } = event.currentTarget.dataset
    this.inputTarget.value = prompt
    this.send(prompt, mode || "text")
  }

  async send(prompt, mode) {
    if (this.streaming) return
    this.streaming = true
    // Stimulus target getters THROW when the element is gone, so the `?.` is not
    // enough — guard with hasXTarget. The empty-state only exists on first send.
    if (this.hasEmptyTarget) this.emptyTarget.remove()
    if (this.hasSuggestionsTarget) this.suggestionsTarget.innerHTML = ""
    this.setBusy(true)

    this.appendUserBubble(prompt)
    const bubble = this.appendAssistantBubble()
    this.resetWire(mode)
    this.inputTarget.value = ""

    let acc = ""
    const setText = (t) => { bubble.textContent = t; this.scroll() }

    try {
      const res = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "",
          "Accept": "text/event-stream"
        },
        body: new URLSearchParams({ prompt, mode })
      })
      if (!res.ok || !res.body) throw new Error(`HTTP ${res.status}`)

      const reader = res.body.getReader()
      const decoder = new TextDecoder()
      let buf = ""

      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        buf += decoder.decode(value, { stream: true })
        let nl
        while ((nl = buf.indexOf("\n")) >= 0) {
          const line = buf.slice(0, nl).trim()
          buf = buf.slice(nl + 1)
          if (!line.startsWith("data:")) continue
          const payload = line.slice(5).trim()
          if (!payload || payload === "[DONE]") continue
          let part
          try { part = JSON.parse(payload) } catch { continue }
          this.wireRow(part)
          acc = this.handlePart(part, bubble, acc, setText)
        }
      }
    } catch (err) {
      bubble.classList.add("text-[var(--color-accent)]")
      setText(acc + `\n\n[stream error: ${err.message}]`)
    } finally {
      this.streaming = false
      this.setBusy(false)
      this.inputTarget.focus()
    }
  }

  // Translate one protocol part into UI. Returns the (possibly updated) text acc.
  handlePart(part, bubble, acc, setText) {
    switch (part.type) {
      case "text-delta":
        acc += part.delta || ""
        setText(acc)
        break
      case "tool-input-start":
        this.toolCard(part.toolCallId, part.toolName)
        break
      case "tool-input-available":
        this.toolField(part.toolCallId, "input", JSON.stringify(part.input))
        break
      case "tool-output-available":
        this.toolField(part.toolCallId, "output", JSON.stringify(part.output))
        this.toolDone(part.toolCallId)
        break
      case "data-suggestions":
        this.renderSuggestions(part.data?.items || [])
        break
      case "error":
        bubble.classList.add("text-[var(--color-accent)]")
        setText((acc ? acc + "\n\n" : "") + (part.errorText || "stream error"))
        break
    }
    return acc
  }

  // ---- transcript ---------------------------------------------------------

  appendUserBubble(text) {
    const row = document.createElement("div")
    row.className = "flex justify-end"
    const b = document.createElement("div")
    b.className = "max-w-[85%] whitespace-pre-wrap rounded-2xl rounded-br-sm bg-[var(--color-accent)] px-3.5 py-2 text-sm text-white"
    b.textContent = text
    row.appendChild(b)
    this.transcriptTarget.appendChild(row)
    this.scroll()
  }

  appendAssistantBubble() {
    const row = document.createElement("div")
    row.className = "flex justify-start"
    const b = document.createElement("div")
    b.className = "max-w-[85%] whitespace-pre-wrap rounded-2xl rounded-bl-sm border hairline bg-[var(--color-surface)] px-3.5 py-2 text-sm text-[var(--color-ink)]"
    b.dataset.assistant = "true"
    row.appendChild(b)
    this.transcriptTarget.appendChild(row)
    this.scroll()
    return b
  }

  // ---- tool-call cards ----------------------------------------------------

  toolCard(id, name) {
    const card = document.createElement("div")
    card.className = "flex justify-start"
    card.innerHTML = `
      <div class="w-full max-w-[85%] overflow-hidden rounded-xl border hairline bg-[var(--color-cool-50)]" data-tool="${id}">
        <div class="flex items-center gap-2 border-b hairline px-3 py-1.5">
          <span class="grid h-4 w-4 place-items-center rounded bg-[var(--color-accent)] font-mono text-[10px] font-bold text-white">ƒ</span>
          <span class="font-mono text-[11px] font-semibold text-[var(--color-ink)]">${name}()</span>
          <span class="ml-auto font-mono text-[10px] text-[var(--color-ink-faint)]" data-tool-status>calling…</span>
        </div>
        <dl class="space-y-1 px-3 py-2 font-mono text-[11px]"></dl>
      </div>`
    this.transcriptTarget.appendChild(card)
    this.scroll()
  }

  toolField(id, label, value) {
    const dl = this.element.querySelector(`[data-tool="${id}"] dl`)
    if (!dl) return
    const row = document.createElement("div")
    row.className = "flex gap-2"
    row.innerHTML =
      `<dt class="shrink-0 uppercase tracking-wide text-[var(--color-ink-faint)]">${label}</dt>` +
      `<dd class="min-w-0 break-all text-[var(--color-ink-soft)]"></dd>`
    row.querySelector("dd").textContent = value
    dl.appendChild(row)
    this.scroll()
  }

  toolDone(id) {
    const s = this.element.querySelector(`[data-tool="${id}"] [data-tool-status]`)
    if (s) { s.textContent = "✓ executed"; s.className = "ml-auto font-mono text-[10px] font-semibold text-emerald-600" }
  }

  // ---- suggestion chips ---------------------------------------------------

  renderSuggestions(items) {
    this.suggestionsTarget.innerHTML = ""
    items.forEach((label) => {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.className = "rounded-full border hairline bg-[var(--color-surface)] px-3 py-1 text-[12px] text-[var(--color-ink-soft)] transition hover:border-[var(--color-accent)] hover:text-[var(--color-ink)]"
      chip.textContent = label
      chip.addEventListener("click", () => { this.inputTarget.value = label; this.inputTarget.focus() })
      this.suggestionsTarget.appendChild(chip)
    })
  }

  // ---- live wire inspector ------------------------------------------------

  resetWire(mode) {
    this.lastDelta = null
    // Clear the idle placeholder the first time real frames arrive.
    this.wireTarget.querySelector("[data-wire-placeholder]")?.remove()
    const head = document.createElement("div")
    head.className = "border-b hairline px-3 py-1.5 font-mono text-[10px] uppercase tracking-[0.16em] text-[var(--color-ink-faint)]"
    head.textContent = `▶ POST /relay/messages (mode: ${mode})`
    this.wireTarget.appendChild(head)
    this.wireScroll()
  }

  // Append one frame. Consecutive *-delta frames collapse into a single row with
  // a running count, so a 200-token answer reads as one line, not 200.
  wireRow(part) {
    const isDelta = part.type.endsWith("-delta")
    if (isDelta && this.lastDelta && this.lastDelta.dataset.type === part.type) {
      const n = (parseInt(this.lastDelta.dataset.n, 10) || 1) + 1
      this.lastDelta.dataset.n = n
      this.lastDelta.querySelector("[data-count]").textContent = `×${n}`
      return
    }

    const row = document.createElement("div")
    row.dataset.type = part.type
    row.dataset.n = "1"
    row.className = "flex items-baseline gap-2 px-3 py-1 font-mono text-[11px] leading-relaxed"
    const color = this.partColor(part.type)
    const summary = this.partSummary(part)
    row.innerHTML =
      `<span class="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-semibold ${color}">${part.type}</span>` +
      `<span class="text-[var(--color-ink-faint)]" data-count>${isDelta ? "×1" : ""}</span>` +
      `<span class="min-w-0 flex-1 truncate text-[var(--color-ink-soft)]"></span>`
    row.querySelector("span:last-child").textContent = summary
    this.wireTarget.appendChild(row)
    this.lastDelta = isDelta ? row : null
    this.wireScroll()
  }

  partColor(type) {
    if (type.startsWith("text")) return "bg-[var(--color-accent-soft)] text-[var(--color-accent)]"
    if (type.startsWith("tool")) return "bg-emerald-100 text-emerald-700"
    if (type.startsWith("data")) return "bg-violet-100 text-violet-700"
    if (type === "error" || type === "abort") return "bg-red-100 text-red-700"
    return "bg-[var(--color-cool-100)] text-[var(--color-ink-soft)]"
  }

  partSummary(part) {
    if (part.delta !== undefined) return JSON.stringify(part.delta)
    if (part.inputTextDelta !== undefined) return JSON.stringify(part.inputTextDelta)
    if (part.input !== undefined) return JSON.stringify(part.input)
    if (part.output !== undefined) return JSON.stringify(part.output)
    if (part.data !== undefined) return JSON.stringify(part.data)
    if (part.toolName) return part.toolName + "()"
    if (part.errorText) return part.errorText
    if (part.messageId) return part.messageId.slice(0, 8) + "…"
    return ""
  }

  // ---- misc ---------------------------------------------------------------

  setBusy(busy) {
    if (this.hasSendTarget) {
      this.sendTarget.disabled = busy
      this.sendTarget.classList.toggle("opacity-50", busy)
    }
    this.element.querySelectorAll("[data-preset]").forEach((b) => (b.disabled = busy))
  }

  scroll() { this.transcriptTarget.scrollTop = this.transcriptTarget.scrollHeight }
  wireScroll() { this.wireTarget.scrollTop = this.wireTarget.scrollHeight }
}
