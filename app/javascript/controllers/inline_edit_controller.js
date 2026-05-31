import { Controller } from "@hotwired/stimulus"

// Click-to-edit with zero latency. The display and the edit form are both
// rendered in the field's Turbo Frame up front; clicking the display reveals
// the form *instantly* (no server round-trip to enter edit mode — that hop was
// the lag). Submitting still PATCHes and the server returns the updated display
// partial, so the server stays authoritative and other clients still morph.
// Without JS, the display is a plain link that GETs the edit form (fallback).
export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit(event) {
    event.preventDefault()
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    if (this.hasInputTarget) {
      this.inputTarget.focus()
      this.inputTarget.select() // Excel-style: type to replace the cell's value
    }
  }

  cancel(event) {
    event?.preventDefault()
    // Discard any unsaved edit and restore the cell's last-saved value.
    if (this.hasInputTarget) this.inputTarget.value = this.inputTarget.defaultValue
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }
}
