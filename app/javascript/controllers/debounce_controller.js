import { Controller } from "@hotwired/stimulus"

// Debounced form auto-submit for live search. Submits the wrapping form into
// its Turbo Frame a short delay after the last keystroke.
export default class extends Controller {
  static values = { delay: { type: Number, default: 250 } }

  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
