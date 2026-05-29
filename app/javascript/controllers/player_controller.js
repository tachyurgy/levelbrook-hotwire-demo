import { Controller } from "@hotwired/stimulus"

// Persistent ambient player. Because this element is data-turbo-permanent it is
// mounted once and survives every navigation/morph — so connect() must not
// restart playback. Audio is decoded into a Web Audio buffer and looped
// sample-accurately (no MP3-padding gap). A GainNode fades in/out smoothly so
// toggling never produces a hard cutout.
export default class extends Controller {
  static targets = ["toggle", "playIcon", "pauseIcon", "viz", "volume"]
  static values = { src: String }

  connect() {
    if (this.constructor.shared) {
      // Reattach to the already-running audio graph after a Turbo morph.
      this.#sync()
      return
    }
    this.constructor.shared = { ctx: null, buffer: null, source: null, gain: null, playing: false, level: 0.6 }
  }

  get state() { return this.constructor.shared }

  async toggle() {
    if (!this.state.ctx) await this.#setup()
    if (this.state.ctx.state === "suspended") await this.state.ctx.resume()

    if (this.state.playing) {
      this.#fadeTo(0, 0.4)
      this.state.playing = false
    } else {
      if (!this.state.source) this.#startSource()
      this.#fadeTo(this.state.level, 0.6)
      this.state.playing = true
    }
    this.#sync()
  }

  volume() {
    this.state.level = Number(this.volumeTarget.value) / 100
    if (this.state.playing) this.#fadeTo(this.state.level, 0.1)
  }

  async #setup() {
    const ctx = new (window.AudioContext || window.webkitAudioContext)()
    const gain = ctx.createGain()
    gain.gain.value = 0
    gain.connect(ctx.destination)

    const response = await fetch(this.srcValue)
    const data = await response.arrayBuffer()
    const buffer = await ctx.decodeAudioData(data)

    Object.assign(this.state, { ctx, gain, buffer })
  }

  #startSource() {
    const { ctx, buffer, gain } = this.state
    const source = ctx.createBufferSource()
    source.buffer = buffer
    source.loop = true
    source.connect(gain)
    source.start(0)
    this.state.source = source
  }

  #fadeTo(target, seconds) {
    const { ctx, gain } = this.state
    const now = ctx.currentTime
    gain.gain.cancelScheduledValues(now)
    gain.gain.setValueAtTime(gain.gain.value, now)
    gain.gain.linearRampToValueAtTime(target, now + seconds)
  }

  #sync() {
    const playing = this.state.playing
    this.playIconTarget?.classList.toggle("hidden", playing)
    this.pauseIconTarget?.classList.toggle("hidden", !playing)
    this.vizTarget?.classList.toggle("hidden", !playing)
    this.vizTarget?.classList.toggle("flex", playing)
    if (this.hasVolumeTarget) this.volumeTarget.value = Math.round(this.state.level * 100)
  }
}
