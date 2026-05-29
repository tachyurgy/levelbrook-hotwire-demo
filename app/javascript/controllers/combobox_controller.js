import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Inline search combobox. Click/focus the box and a results panel drops down
// right underneath it — no modal, no dialog. Typing debounces a fetch of the
// server-rendered results frame and injects it into the panel; arrow keys
// navigate, Enter opens the selected result. Without JS the wrapping form just
// submits to the full /search page (progressive enhancement).
export default class extends Controller {
  static targets = ["input", "panel", "results"]
  static values = { url: String, delay: { type: Number, default: 120 } }

  connect() {
    this.onDocClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.onDocClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocClick)
    clearTimeout(this.timer)
  }

  open() {
    this.panelTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  search() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.#fetch(), this.delayValue)
    this.open()
  }

  async #fetch() {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", this.inputTarget.value)
    const response = await get(url.toString(), { responseKind: "html" })
    if (!response.ok) return
    const html = await response.html
    const fresh = new DOMParser().parseFromString(html, "text/html").querySelector("#search_results")
    if (fresh) this.resultsTarget.innerHTML = fresh.innerHTML
    this.open()
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-combobox-target='item']"))
  }

  next(event) { event.preventDefault(); this.#move(1) }
  prev(event) { event.preventDefault(); this.#move(-1) }

  select(event) {
    const items = this.items
    const current = items.find((i) => i.getAttribute("aria-selected") === "true") || items[0]
    if (current) {
      event.preventDefault()
      current.click()
      this.close()
      this.inputTarget.blur()
    }
  }

  #move(delta) {
    const items = this.items
    if (items.length === 0) return
    let index = items.findIndex((i) => i.getAttribute("aria-selected") === "true")
    index = (index + delta + items.length) % items.length
    items.forEach((item, i) => {
      if (i === index) {
        item.setAttribute("aria-selected", "true")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.removeAttribute("aria-selected")
      }
    })
  }
}
