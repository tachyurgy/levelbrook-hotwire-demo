import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

// Optimistic live-poll voting. On click we recompute every bar from the new
// total *immediately* (optimistic), remember the choice in localStorage, then
// POST. The server records the vote and the room's broadcasts_refreshes morphs
// the authoritative tallies back onto every client. On each morph, connect()
// re-applies this browser's "voted" state (morph-survival via Stimulus).
export default class extends Controller {
  static targets = ["option", "total"]
  static values = { id: String, voteUrl: String }

  connect() {
    this.applyVoted()
  }

  get storageKey() {
    return `ballot-poll-${this.idValue}`
  }

  vote(event) {
    const button = event.currentTarget
    if (button.disabled) return
    const optionId = button.dataset.optionId

    // Optimistic: +1 the chosen option, then recompute all shares.
    const rows = this.optionTargets.map((el) => ({
      el,
      count: parseInt(el.querySelector("[data-count]").textContent, 10) || 0
    }))
    const chosen = rows.find((r) => r.el === button)
    chosen.count += 1
    const total = rows.reduce((sum, r) => sum + r.count, 0)
    rows.forEach((r) => {
      const pct = total ? Math.round((r.count / total) * 100) : 0
      r.el.querySelector("[data-count]").textContent = r.count
      r.el.querySelector("[data-pct]").textContent = `${pct}%`
      r.el.querySelector("[data-bar]").style.width = `${pct}%`
    })
    if (this.hasTotalTarget) this.totalTarget.textContent = total

    localStorage.setItem(this.storageKey, optionId)
    this.applyVoted()

    post(this.voteUrlValue, { body: { option_id: optionId }, responseKind: "turbo-stream" })
  }

  applyVoted() {
    const choice = localStorage.getItem(this.storageKey)
    if (!choice) return
    this.optionTargets.forEach((el) => {
      el.disabled = true
      const mine = el.dataset.optionId === choice
      el.classList.toggle("ring-2", mine)
      el.classList.toggle("ring-[var(--color-accent)]", mine)
      el.classList.toggle("border-[var(--color-accent)]", mine)
    })
  }
}
