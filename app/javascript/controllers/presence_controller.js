import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

// Anonymous presence for the public board, modeled on Campfire's presence
// controller: subscribe on connect, tear the subscription down on disconnect.
// The server keeps a per-board connection count and broadcasts the rendered
// badge HTML; we morph it into place. No identity, no auth — this board is
// public, so "N viewers" is just live connection count.
export default class extends Controller {
  static values = { boardId: Number }

  async connect() {
    this.channel = await cable.subscribeTo(
      { channel: "PresenceChannel", board_id: this.boardIdValue },
      { received: this.#received }
    )
  }

  disconnect() {
    this.channel?.unsubscribe()
  }

  #received = (html) => {
    if (typeof html !== "string") return
    const badge = this.element.querySelector("#board_presence")
    if (badge) badge.outerHTML = html
  }
}
