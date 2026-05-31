import { Controller } from "@hotwired/stimulus"

// The Cadence channel rail lives OUTSIDE the conversation frame, so frame
// navigation changes the URL without re-rendering this list. Two jobs:
//   1. keep the matching link flagged aria-current as the URL changes;
//   2. eagerly warm every channel's frame so the first click is instant.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sync = this.sync.bind(this)
    document.addEventListener("turbo:load", this.sync)
    document.addEventListener("turbo:frame-render", this.sync)
    this.sync()
    this.warm()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.sync)
    document.removeEventListener("turbo:frame-render", this.sync)
  }

  // Flag the link whose path matches the current URL; clear the rest.
  sync() {
    const path = window.location.pathname
    this.linkTargets.forEach((link) => {
      if (new URL(link.href).pathname === path) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  // Fetch each channel's frame once, up front, so the server has rendered and
  // cached it before the user clicks. Turbo's hover prefetch fills the snapshot
  // cache; this removes the cold-render cost sitting behind it.
  warm() {
    this.linkTargets.forEach((link) => {
      fetch(link.href, {
        headers: { Accept: "text/html", "Turbo-Frame": "conversation" },
        credentials: "same-origin"
      }).catch(() => {})
    })
  }
}
