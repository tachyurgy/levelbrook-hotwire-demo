import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// ⌘K command palette. Opens on the hotkey, debounces typing into a Turbo Frame
// fetch of server-rendered results, and arrow-key navigates them. Enter visits
// the selected result. No client search index — the server ranks results.
export default class extends Controller {
  static targets = ["dialog", "input", "results"]
  static values = { url: String }

  open(event) {
    event?.preventDefault()
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  close(event) {
    event?.preventDefault()
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close(event)
  }

  search() {
    clearTimeout(this.timer)
    this.timer = setTimeout(async () => {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", this.inputTarget.value)
      const response = await get(url.toString(), { responseKind: "html" })
      if (response.ok) {
        const html = await response.html
        // The response is a <turbo-frame id="command_results">; swap it in.
        const doc = new DOMParser().parseFromString(html, "text/html")
        const fresh = doc.querySelector("#command_results")
        if (fresh) this.resultsTarget.replaceWith(fresh)
      }
    }, 140)
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-command-palette-target='item']"))
  }

  next(event) {
    event.preventDefault()
    this.#move(1)
  }

  prev(event) {
    event.preventDefault()
    this.#move(-1)
  }

  hover(event) {
    this.#select(this.items.indexOf(event.currentTarget))
  }

  select(event) {
    event.preventDefault()
    const current = this.items.find((i) => i.getAttribute("aria-selected") === "true") || this.items[0]
    if (current) Turbo.visit(current.getAttribute("href"))
    this.close()
  }

  go(event) {
    // Click on a result: let the browser/Turbo follow it, then close.
    this.close()
  }

  #move(delta) {
    const items = this.items
    if (items.length === 0) return
    let index = items.findIndex((i) => i.getAttribute("aria-selected") === "true")
    index = (index + delta + items.length) % items.length
    this.#select(index)
  }

  #select(index) {
    this.items.forEach((item, i) => {
      if (i === index) {
        item.setAttribute("aria-selected", "true")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.removeAttribute("aria-selected")
      }
    })
  }
}
