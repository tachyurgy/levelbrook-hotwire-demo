import { Controller } from "@hotwired/stimulus"

// Drives the lazy-frame modal <dialog>. Opens when content loads into the
// frame, closes on ESC / backdrop / the close button, and clears the frame on
// close so the next card reloads fresh.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    // Close the modal after a successful inline-edit/comment submit that redirects.
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd)
  }

  // Fired by turbo:frame-load on the modal frame. If the frame got content, show.
  opened(event) {
    const frame = event.target
    if (frame.id === "modal" && frame.innerHTML.trim() !== "") {
      this.open()
    }
  }

  open() {
    if (this.hasDialogTarget && !this.dialogTarget.open) {
      this.dialogTarget.showModal()
    }
  }

  close(event) {
    event?.preventDefault()
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
  }

  dismiss() {
    this.#clearFrame()
  }

  // Clicking the dialog's ::backdrop registers as a click on the dialog itself.
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close(event)
  }

  handleSubmitEnd = (event) => {
    if (event.detail?.success && event.detail.fetchResponse?.redirected) {
      this.close()
    }
  }

  #clearFrame() {
    const frame = this.element.querySelector("#modal")
    if (frame) frame.innerHTML = ""
  }
}
