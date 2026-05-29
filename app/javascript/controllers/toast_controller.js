import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast after a timeout with a fade-out transition.
export default class extends Controller {
  static targets = ["root"]
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.style.transition = "opacity 200ms, transform 200ms"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(8px)"
    setTimeout(() => this.element.remove(), 220)
  }
}
