import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

// Relays "X is typing…" over the TypingChannel (raw cable, nothing persisted).
// Throttles start events; auto-stops after a pause; renders others' names.
export default class extends Controller {
  static targets = ["indicator", "author", "input"]
  static values = { slug: String, name: String }

  async connect() {
    this.typers = new Map()
    this.channel = await cable.subscribeTo(
      { channel: "TypingChannel", slug: this.slugValue },
      { received: this.received.bind(this) }
    )
    this.purger = setInterval(() => this.#purge(), 1000)
  }

  disconnect() {
    clearInterval(this.purger)
    clearTimeout(this.stopTimer)
    this.channel?.unsubscribe()
  }

  changed() {
    if (this.inputTarget.value.trim() === "") {
      this.#send("stop")
      return
    }
    if (!this.sentStart) {
      this.channel?.perform("start")
      this.sentStart = true
    }
    clearTimeout(this.stopTimer)
    this.stopTimer = setTimeout(() => this.#send("stop"), 3000)
  }

  received({ action, name }) {
    if (name === this.nameValue) return
    if (action === "start") {
      this.typers.set(name, Date.now())
    } else {
      this.typers.delete(name)
    }
    this.#render()
  }

  #send(action) {
    if (action === "stop" && this.sentStart) {
      this.channel?.perform("stop")
      this.sentStart = false
    }
  }

  #purge() {
    const cutoff = Date.now() - 5000
    let changed = false
    for (const [name, at] of this.typers) {
      if (at < cutoff) { this.typers.delete(name); changed = true }
    }
    if (changed) this.#render()
  }

  #render() {
    const names = [...this.typers.keys()].sort()
    if (names.length === 0) {
      this.indicatorTarget.classList.add("hidden")
    } else {
      this.authorTarget.textContent = names.join(", ")
      this.indicatorTarget.classList.remove("hidden")
    }
  }
}
