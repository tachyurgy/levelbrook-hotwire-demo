import { Controller } from "@hotwired/stimulus"

// Closes a native <details> popover on outside-click and Escape. Used by the
// "switch demo" menu in the topbar so it behaves like a real dropdown without
// pulling in a menu library.
export default class extends Controller {
  connect() {
    this.onDocClick = (event) => {
      if (!this.element.contains(event.target)) this.element.removeAttribute("open")
    }
    this.onKey = (event) => {
      if (event.key === "Escape") this.element.removeAttribute("open")
    }
    document.addEventListener("click", this.onDocClick)
    document.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocClick)
    document.removeEventListener("keydown", this.onKey)
  }

  sync() {}
}
