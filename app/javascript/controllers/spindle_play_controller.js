import { Controller } from "@hotwired/stimulus"

// A track row's play button. It just dispatches a `spindle:play` window event
// with the track payload; the persistent player (synth_controller) listens and
// takes over. This decoupling is what lets the page re-render while the
// permanent player keeps playing.
export default class extends Controller {
  static values = { track: Object }

  play() {
    window.dispatchEvent(new CustomEvent("spindle:play", { detail: this.trackValue }))
  }
}
