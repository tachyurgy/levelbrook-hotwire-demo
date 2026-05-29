import { Controller } from "@hotwired/stimulus"

// Keeps the message list pinned to the bottom as messages stream in.
export default class extends Controller {
  static targets = ["scroll"]

  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.scrollTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.scrollTarget.scrollTop = this.scrollTarget.scrollHeight
  }
}
