import { Controller } from "@hotwired/stimulus"

// The persistent player's brain. Owns ONE Web Audio graph and a lookahead
// scheduler that synthesizes the current track live — no audio files. Because
// the host element is data-turbo-permanent, this controller is created once and
// survives every Turbo navigation inside Spindle, so playback never cuts out.
//
// Tracks are chord progressions (open fifths + octaves — always consonant, no
// droning). `texture` shapes the arrangement: keys / pad / pluck / beat. Audio
// is only ever started by the user (toggle, or a track row dispatching
// `spindle:play`) — it never auto-plays.
export default class extends Controller {
  static targets = ["playIcon", "pauseIcon", "title", "artist", "viz", "bar", "volume"]

  connect() {
    this.state = { playing: false, track: null, level: 0.5, beat: 0, nextTime: 0 }
    this.onPlay = (event) => this.load(event.detail)
    window.addEventListener("spindle:play", this.onPlay)
    if (this.hasVolumeTarget) this.state.level = Number(this.volumeTarget.value) / 100
  }

  disconnect() {
    window.removeEventListener("spindle:play", this.onPlay)
    this.#stopScheduler()
  }

  // --- transport -------------------------------------------------------

  load(track) {
    this.#ensureAudio()
    this.state.track = track
    this.state.beat = 0
    if (this.hasTitleTarget) this.titleTarget.textContent = track.title
    if (this.hasArtistTarget) this.artistTarget.textContent = `${track.artist} · ${track.album}`
    this.play()
  }

  toggle() {
    this.state.playing ? this.pause() : this.play()
  }

  play() {
    if (!this.state.track) return
    this.#ensureAudio()
    if (this.ctx.state === "suspended") this.ctx.resume()
    this.state.playing = true
    this.state.nextTime = this.ctx.currentTime + 0.06
    this.#startScheduler()
    this.#reflect()
  }

  pause() {
    this.state.playing = false
    this.#stopScheduler()
    this.#reflect()
  }

  volume() {
    this.state.level = Number(this.volumeTarget.value) / 100
    if (this.master) this.master.gain.setTargetAtTime(this.state.level, this.ctx.currentTime, 0.05)
  }

  // --- audio graph -----------------------------------------------------

  #ensureAudio() {
    if (this.ctx) return
    const ctx = new (window.AudioContext || window.webkitAudioContext)()
    const master = ctx.createGain(); master.gain.value = this.state.level
    const filter = ctx.createBiquadFilter(); filter.type = "lowpass"; filter.frequency.value = 1900; filter.Q.value = 0.6
    const delay = ctx.createDelay(); delay.delayTime.value = 0.34
    const feedback = ctx.createGain(); feedback.gain.value = 0.24
    const wet = ctx.createGain(); wet.gain.value = 0.18
    filter.connect(master)
    filter.connect(delay); delay.connect(feedback); feedback.connect(delay); delay.connect(wet); wet.connect(master)
    master.connect(ctx.destination)
    this.ctx = ctx; this.master = master; this.filter = filter
  }

  #startScheduler() {
    if (this.timer) return
    this.timer = setInterval(() => this.#schedule(), 25)
  }

  #stopScheduler() {
    clearInterval(this.timer); this.timer = null
  }

  #schedule() {
    const track = this.state.track
    if (!track || !this.state.playing) return
    const secPerBeat = 60 / track.bpm
    while (this.state.nextTime < this.ctx.currentTime + 0.12) {
      this.#scheduleBeat(this.state.nextTime, this.state.beat, track, secPerBeat)
      this.state.beat += 1
      this.state.nextTime += secPerBeat
    }
  }

  #scheduleBeat(time, beat, track, spb) {
    const roots = track.roots
    const bar = Math.floor(beat / 4)
    const inBar = beat % 4
    const root = roots[bar % roots.length]
    const voicing = [root, root + 7, root + 12] // open fifth + octave — always consonant

    switch (track.texture) {
      case "pad":
        if (inBar === 0) this.#chord(voicing.concat(root + 19), time, spb * 4, 0.16, "sine", 0.9)
        break
      case "pluck": {
        const note = voicing[inBar % voicing.length] + 12
        this.#note(note, time, 0.28, 0.2, "sawtooth", 0.004)
        if (inBar === 0) this.#note(root - 12, time, spb * 1.5, 0.14, "triangle")
        break
      }
      case "beat":
        this.#kick(time)
        if (inBar === 0 || inBar === 2) this.#note(root - 12, time, 0.28, 0.22, "triangle")
        this.#chord(voicing, time, 0.32, 0.09, "triangle", 0.008)
        break
      default: // keys
        this.#chord(voicing, time, spb * 1.1, 0.13, "triangle", 0.012)
        if (inBar === 0) this.#note(root - 12, time, spb * 1.5, 0.11, "sine")
    }

    const progress = (((bar % roots.length) + inBar / 4) / roots.length) * 100
    if (this.hasBarTarget) this.barTarget.style.width = `${progress.toFixed(1)}%`
  }

  #chord(notes, time, dur, gain, type, attack) {
    notes.forEach((n) => this.#note(n, time, dur, gain, type, attack))
  }

  #note(midi, time, dur, gain, type, attack = 0.01) {
    const osc = this.ctx.createOscillator()
    osc.type = type
    osc.frequency.value = 440 * Math.pow(2, (midi - 69) / 12)
    osc.detune.value = Math.random() * 6 - 3
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.linearRampToValueAtTime(gain, time + attack)
    g.gain.exponentialRampToValueAtTime(0.0001, time + dur)
    osc.connect(g); g.connect(this.filter)
    osc.start(time); osc.stop(time + dur + 0.05)
  }

  #kick(time) {
    const osc = this.ctx.createOscillator()
    osc.frequency.setValueAtTime(130, time)
    osc.frequency.exponentialRampToValueAtTime(45, time + 0.12)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.5, time)
    g.gain.exponentialRampToValueAtTime(0.0001, time + 0.18)
    osc.connect(g); g.connect(this.master)
    osc.start(time); osc.stop(time + 0.2)
  }

  #reflect() {
    const playing = this.state.playing
    this.playIconTarget?.classList.toggle("hidden", playing)
    this.pauseIconTarget?.classList.toggle("hidden", !playing)
    this.vizTarget?.classList.toggle("is-playing", playing)
  }
}
