import { Controller } from "@hotwired/stimulus"

// Ambient audio for the story. Generates a soft evolving drone with the Web
// Audio API so there's no asset to ship and the sound loops seamlessly. The bar
// is data-turbo-permanent, so this controller connects once and survives every
// scene navigation — the audio never restarts as you read. We keep play state
// in the DOM-bound controller instance, which is safe precisely because the
// element is permanent (a morph would otherwise reset it).
export default class extends Controller {
  static targets = ["icon", "status", "button"]

  connect() {
    this.playing = false
  }

  disconnect() {
    // Only runs if the permanent element is ever removed (e.g. leaving the
    // story). Tear the audio graph down so nothing leaks.
    this.#stop()
  }

  toggle() {
    this.playing ? this.#stop() : this.#start()
  }

  #start() {
    this.ctx ||= new (window.AudioContext || window.webkitAudioContext)()
    this.ctx.resume()

    this.master = this.ctx.createGain()
    this.master.gain.value = 0
    this.master.connect(this.ctx.destination)

    // Two slightly detuned low oscillators + a slow LFO on the filter give a
    // calm, cinematic drone without any audio file.
    this.osc = [110, 110.4, 165].map((freq) => {
      const o = this.ctx.createOscillator()
      o.type = "sine"
      o.frequency.value = freq
      o.connect(this.master)
      o.start()
      return o
    })

    this.filter = this.ctx.createBiquadFilter()
    this.filter.type = "lowpass"
    this.filter.frequency.value = 600

    // Fade in.
    this.master.gain.linearRampToValueAtTime(0.06, this.ctx.currentTime + 1.5)

    this.playing = true
    this.iconTarget.textContent = "❚❚"
    this.statusTarget.textContent = "Playing — drifts with you between scenes"
    this.buttonTarget.classList.add("text-orange-300", "border-orange-400/40")
  }

  #stop() {
    if (this.master && this.ctx) {
      this.master.gain.linearRampToValueAtTime(0, this.ctx.currentTime + 0.4)
      const osc = this.osc
      setTimeout(() => osc?.forEach((o) => o.stop()), 500)
    }
    this.playing = false
    if (this.hasIconTarget) {
      this.iconTarget.textContent = "♪"
      this.statusTarget.textContent = "Muted — tap to play"
      this.buttonTarget.classList.remove("text-orange-300", "border-orange-400/40")
    }
  }
}
