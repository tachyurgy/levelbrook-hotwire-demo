import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

// Subscribes to a channel's PresenceChannel, heartbeats while visible, and
// renders the live roster of avatars. Presence is ephemeral raw-cable JSON.
export default class extends Controller {
  static targets = ["roster"]
  static values = { slug: String }

  async connect() {
    this.channel = await cable.subscribeTo(
      { channel: "PresenceChannel", slug: this.slugValue },
      { received: this.received.bind(this) }
    )
    this.heartbeat = setInterval(() => this.channel?.perform("present"), 30000)
    document.addEventListener("visibilitychange", this.onVisibility)
  }

  disconnect() {
    clearInterval(this.heartbeat)
    document.removeEventListener("visibilitychange", this.onVisibility)
    this.channel?.unsubscribe()
  }

  onVisibility = () => {
    if (document.visibilityState === "visible") this.channel?.perform("present")
  }

  received(data) {
    if (!data.names) return
    this.rosterTarget.innerHTML = data.names.map((name) => this.#avatar(name)).join("")
  }

  #avatar(name) {
    const initials = name.split(" ").map((p) => p[0]).slice(0, 2).join("").toUpperCase()
    return `<span title="${name}" class="grid h-6 w-6 place-items-center rounded-full bg-emerald-100 text-emerald-700 font-mono text-[9px] font-semibold ring-1 ring-emerald-200">${initials}</span>`
  }
}
