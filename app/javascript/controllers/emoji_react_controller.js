import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

// Optimistic emoji reactions. Bumps the count instantly and POSTs; the server
// records it and broadcast_replaces the message, reconciling for every client.
export default class extends Controller {
  static values = { url: String }

  react(event) {
    const button = event.currentTarget
    const countEl = button.querySelector("[data-count]")
    countEl.textContent = (parseInt(countEl.textContent, 10) || 0) + 1
    button.classList.remove("opacity-45")
    button.classList.add("border-[var(--color-accent)]")
    post(this.urlValue, { body: { emoji: button.dataset.emoji }, responseKind: "turbo-stream" })
  }
}
