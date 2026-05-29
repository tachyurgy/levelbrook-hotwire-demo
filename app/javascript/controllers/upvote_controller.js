import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

// Optimistic question upvote. Bumps the count instantly, locks the button via
// localStorage, and POSTs. The room morph reconciles the count and re-sorts the
// list; connect() re-locks the button after each morph.
export default class extends Controller {
  static targets = ["count"]
  static values = { id: String, url: String }

  connect() {
    if (localStorage.getItem(this.storageKey)) this.lock()
  }

  get storageKey() {
    return `ballot-q-${this.idValue}`
  }

  cast() {
    if (localStorage.getItem(this.storageKey)) return
    this.countTarget.textContent = (parseInt(this.countTarget.textContent, 10) || 0) + 1
    localStorage.setItem(this.storageKey, "1")
    this.lock()
    post(this.urlValue, { responseKind: "turbo-stream" })
  }

  lock() {
    this.element.querySelector("button").disabled = true
  }
}
