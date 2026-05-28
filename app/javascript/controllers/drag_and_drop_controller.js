import { Controller } from "@hotwired/stimulus"

// HTML5 drag-and-drop for the Kanban board — no SortableJS, no third-party lib.
// Adapted from the Fizzy idiom: the board is the controller, columns are drop
// "containers", cards are draggable "items". On drop we move the card in the
// DOM optimistically (so it feels instant), compute its new index, and POST the
// move. The server renumbers positions and broadcasts a refresh; Turbo morphs
// every connected browser — including this one — into the canonical state.
export default class extends Controller {
  static targets = ["item", "container"]
  static classes = ["dragging", "over"]

  connect() {
    this.dragItem = null
  }

  dragStart(event) {
    const item = this.#itemContaining(event.target)
    if (!item) return

    this.dragItem = item
    this.sourceContainer = this.#containerContaining(item)
    event.dataTransfer.effectAllowed = "move"
    // Defer the class so the drag image is captured without the dimmed style.
    requestAnimationFrame(() => item.classList.add(this.draggingClass))
  }

  dragOver(event) {
    if (!this.dragItem) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const container = this.#containerContaining(event.target)
    this.#clearOver()
    if (!container) return
    container.classList.add(this.overClass)

    // Live preview: insert the dragged item before the card we're hovering.
    const list = this.#listOf(container)
    const after = this.#itemAfter(list, event.clientY)
    if (after == null) {
      list.appendChild(this.dragItem)
    } else if (after !== this.dragItem) {
      list.insertBefore(this.dragItem, after)
    }
  }

  async drop(event) {
    if (!this.dragItem) return
    event.preventDefault()

    const container = this.#containerContaining(event.target) || this.sourceContainer
    const list = this.#listOf(container)
    const position = Array.from(list.querySelectorAll("[data-card-id]")).indexOf(this.dragItem)

    this.#updateCounts()
    await this.#persist(container, this.dragItem, position)
  }

  dragEnd() {
    this.dragItem?.classList.remove(this.draggingClass)
    this.#clearOver()
    this.dragItem = null
    this.sourceContainer = null
  }

  // --- private ---

  #persist(container, item, position) {
    const url = container.dataset.dropUrl.replace("__id__", item.dataset.cardId)
    const body = new FormData()
    body.append("column_id", container.dataset.columnId)
    body.append("position", position)

    return fetch(url, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.#csrf, Accept: "text/vnd.turbo-stream.html" },
      body
    })
  }

  #itemContaining(el) {
    return this.itemTargets.find((item) => item === el || item.contains(el))
  }

  #containerContaining(el) {
    return this.containerTargets.find((c) => c === el || c.contains(el))
  }

  #listOf(container) {
    return container.querySelector("[data-card-list]")
  }

  // Find the first card whose vertical midpoint is below the cursor.
  #itemAfter(list, y) {
    const cards = Array.from(list.querySelectorAll("[data-card-id]:not(.opacity-40)"))
    return cards.find((card) => {
      const box = card.getBoundingClientRect()
      return y < box.top + box.height / 2
    }) || null
  }

  #updateCounts() {
    this.containerTargets.forEach((container) => {
      const counter = container.querySelector("[data-drag-and-drop-counter]")
      if (counter) counter.textContent = this.#listOf(container).querySelectorAll("[data-card-id]").length
    })
  }

  #clearOver() {
    this.containerTargets.forEach((c) => c.classList.remove(this.overClass))
  }

  get #csrf() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
