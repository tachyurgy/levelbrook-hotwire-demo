import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { put } from "@rails/request.js"

// Thin SortableJS wrapper. On drop we PUT the card's new column + position;
// the server reorders and the Project's broadcasts_refreshes morphs every
// connected board. Drag state is DOM-resident so the morph never fights the drag.
export default class extends Controller {
  static values = { group: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: this.groupValue || "shared",
      animation: 150,
      ghostClass: "sortable-ghost",
      dragClass: "sortable-drag",
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  async onEnd(event) {
    const card = event.item
    const url = card.dataset.positionUrl
    const columnId = event.to.dataset.columnId
    const position = event.newIndex

    if (!url) return

    await put(url, {
      body: JSON.stringify({ column_id: columnId, position }),
      contentType: "application/json"
    })
  }
}
