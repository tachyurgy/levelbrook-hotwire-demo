import { Controller } from "@hotwired/stimulus"

// Small form helpers: submit on Enter (without Shift) for single-line composers,
// and an explicit requestSubmit action for auto-submitting selects.
export default class extends Controller {
  requestSubmit(event) {
    event.target.form?.requestSubmit()
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit?.() || event.target.form?.requestSubmit()
    }
  }
}
