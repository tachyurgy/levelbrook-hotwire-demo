import { Controller } from "@hotwired/stimulus"

// The persistent player's brain. Owns ONE Web Audio graph that survives every
// Turbo navigation (the host element is data-turbo-permanent), so playback
// never cuts out as you browse. It plays tracks two ways:
//
//   * FILE tracks (audioUrl present) stream a real CC0 recording through the
//     same graph — so the volume slider and progress bar work uniformly.
//   * SYNTH tracks have NO audio file: a lookahead scheduler renders the chord
//     progression live with oscillators. The point is the engineering, not the
//     fidelity — the UI says so. The sound design here (detuned voices, ADSR,
//     a convolution reverb, tape-ish saturation, soft lo-fi drums) makes the
//     live render warm rather than buzzy.
//
// Audio is only ever started by the user — it never auto-plays.
export default class extends Controller {
  static targets = ["playIcon", "pauseIcon", "title", "artist", "viz", "bar", "volume", "mode"]

  connect() {
    this.state = { playing: false, track: null, level: 0.5, beat: 0, nextTime: 0, mode: null }
    this.onPlay = (event) => this.load(event.detail)
    window.addEventListener("spindle:play", this.onPlay)
    if (this.hasVolumeTarget) this.state.level = Number(this.volumeTarget.value) / 100
  }

  disconnect() {
    window.removeEventListener("spindle:play", this.onPlay)
    this.#stopScheduler()
    this.#stopProgress()
    if (this.audioEl) this.audioEl.pause()
  }

  // --- transport -------------------------------------------------------

  load(track) {
    this.#ensureAudio()
    this.#stopScheduler()
    this.#stopProgress()
    if (this.audioEl) { this.audioEl.pause() }

    this.state.track = track
    this.state.beat = 0
    this.state.mode = track.audioUrl ? "file" : "synth"
    if (this.hasTitleTarget) this.titleTarget.textContent = track.title
    if (this.hasArtistTarget) this.artistTarget.textContent = `${track.artist} · ${track.album}`
    if (this.hasBarTarget) this.barTarget.style.width = "0%"
    if (this.hasModeTarget) {
      const file = this.state.mode === "file"
      this.modeTarget.textContent = file ? "CC0 file" : "live synth"
      this.modeTarget.className = `shrink-0 rounded-full px-1.5 py-px font-mono text-[9px] font-medium ${
        file ? "bg-emerald-50 text-emerald-700" : "bg-[var(--color-accent)]/10 text-[var(--color-accent)]"
      }`
    }

    if (this.state.mode === "file") {
      this.#ensureMediaSource()
      if (this.audioEl.src !== new URL(track.audioUrl, location.href).href) {
        this.audioEl.src = track.audioUrl
      }
      this.audioEl.currentTime = 0
    }
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

    if (this.state.mode === "file") {
      this.audioEl.play().catch(() => {})
      this.#startProgress()
    } else {
      this.state.nextTime = this.ctx.currentTime + 0.08
      this.#startScheduler()
    }
    this.#reflect()
  }

  pause() {
    this.state.playing = false
    this.#stopScheduler()
    this.#stopProgress()
    if (this.state.mode === "file" && this.audioEl) this.audioEl.pause()
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

    // Master chain: bus -> warmth lowpass -> tape saturation -> compressor
    //                   -> master gain (volume) -> destination, with a parallel
    // convolution-reverb send for space.
    const master = ctx.createGain(); master.gain.value = this.state.level
    const comp = ctx.createDynamicsCompressor()
    comp.threshold.value = -18; comp.knee.value = 24; comp.ratio.value = 3
    comp.attack.value = 0.006; comp.release.value = 0.25

    const shaper = ctx.createWaveShaper()
    shaper.curve = this.#saturationCurve(0.4)
    shaper.oversample = "2x"

    const tone = ctx.createBiquadFilter()
    tone.type = "lowpass"; tone.frequency.value = 5200; tone.Q.value = 0.4

    const bus = ctx.createGain(); bus.gain.value = 0.9

    // reverb send
    const reverb = ctx.createConvolver()
    reverb.buffer = this.#impulseResponse(ctx, 2.6, 2.4)
    const reverbSend = ctx.createGain(); reverbSend.gain.value = 0.32
    const reverbReturn = ctx.createGain(); reverbReturn.gain.value = 0.9

    bus.connect(tone)
    bus.connect(reverbSend); reverbSend.connect(reverb); reverb.connect(reverbReturn); reverbReturn.connect(shaper)
    tone.connect(shaper)
    shaper.connect(comp); comp.connect(master); master.connect(ctx.destination)

    this.ctx = ctx
    this.master = master
    this.bus = bus
  }

  // A real <audio> element streamed through the bus so volume/effects apply.
  // MediaElementSource can only be created once per element, so cache both.
  #ensureMediaSource() {
    if (this.mediaNode) return
    this.audioEl = new Audio()
    this.audioEl.crossOrigin = "anonymous"
    this.audioEl.loop = true
    this.audioEl.preload = "auto"
    this.mediaNode = this.ctx.createMediaElementSource(this.audioEl)
    const trim = this.ctx.createGain(); trim.gain.value = 0.85 // recordings are hotter than the synth
    this.mediaNode.connect(trim); trim.connect(this.bus)
  }

  // --- progress (file mode) -------------------------------------------

  #startProgress() {
    this.#stopProgress()
    const tick = () => {
      if (!this.audioEl || !this.state.playing) return
      const d = this.audioEl.duration
      if (this.hasBarTarget && d && isFinite(d)) {
        this.barTarget.style.width = `${((this.audioEl.currentTime / d) * 100).toFixed(1)}%`
      }
      this.raf = requestAnimationFrame(tick)
    }
    this.raf = requestAnimationFrame(tick)
  }

  #stopProgress() {
    if (this.raf) cancelAnimationFrame(this.raf)
    this.raf = null
  }

  // --- scheduler (synth mode) -----------------------------------------

  #startScheduler() {
    if (this.timer) return
    this.timer = setInterval(() => this.#schedule(), 25)
  }

  #stopScheduler() {
    clearInterval(this.timer); this.timer = null
  }

  #schedule() {
    const track = this.state.track
    if (!track || !this.state.playing || this.state.mode !== "synth") return
    const secPerBeat = 60 / track.bpm
    while (this.state.nextTime < this.ctx.currentTime + 0.14) {
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
    // Warm, lush voicing: root + fifth + octave + major-9th colour. Stacked so
    // it's consonant regardless of the progression in the seed data.
    const pad = [root, root + 7, root + 12, root + 16, root + 19]
    const chord = [root, root + 7, root + 12]

    switch (track.texture) {
      case "pad":
        if (inBar === 0) pad.forEach((n, i) =>
          this.#voice(n, time, spb * 4.2, { gain: 0.07, type: "sine", attack: 0.6, release: 1.8, detune: 5, pan: (i - 2) * 0.18 }))
        break
      case "pluck": {
        const note = chord[inBar % chord.length] + 12
        this.#voice(note, time, 0.6, { gain: 0.12, type: "triangle", attack: 0.004, release: 0.5, detune: 4, pan: 0.2 })
        if (inBar === 0) this.#voice(root - 12, time, spb * 1.6, { gain: 0.1, type: "sine", attack: 0.02, release: 0.6 })
        break
      }
      case "beat":
        this.#kick(time)
        if (inBar === 1 || inBar === 3) this.#hat(time)
        if (inBar === 0 || inBar === 2) this.#voice(root - 12, time, 0.34, { gain: 0.14, type: "triangle", attack: 0.01, release: 0.2 })
        if (inBar === 0) chord.forEach((n) => this.#epiano(n, time, spb * 2.2, 0.06))
        break
      default: // keys — FM electric piano (Rhodes-ish), much warmer than a raw osc
        if (inBar % 2 === 0) chord.forEach((n, i) => this.#epiano(n + 12, time, spb * 1.8, 0.075, (i - 1) * 0.2))
        if (inBar === 0) this.#voice(root - 12, time, spb * 1.8, { gain: 0.08, type: "sine", attack: 0.02, release: 0.9 })
    }

    const progress = (((bar % roots.length) + inBar / 4) / roots.length) * 100
    if (this.hasBarTarget) this.barTarget.style.width = `${progress.toFixed(1)}%`
  }

  // A single voice: two slightly detuned oscillators (warmth) through an ADSR
  // gain and an optional stereo pan, summed into the bus.
  #voice(midi, time, dur, { gain = 0.1, type = "sine", attack = 0.01, release = 0.3, detune = 0, pan = 0 } = {}) {
    const freq = 440 * Math.pow(2, (midi - 69) / 12)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.linearRampToValueAtTime(gain, time + attack)
    g.gain.setValueAtTime(gain, time + dur)
    g.gain.exponentialRampToValueAtTime(0.0001, time + dur + release)

    const out = pan ? this.ctx.createStereoPanner() : g
    if (pan) { out.pan.value = Math.max(-1, Math.min(1, pan)); g.connect(out) }

    ;[-detune, detune].forEach((d) => {
      const osc = this.ctx.createOscillator()
      osc.type = type
      osc.frequency.value = freq
      osc.detune.value = d
      osc.connect(g)
      osc.start(time)
      osc.stop(time + dur + release + 0.05)
    })
    out.connect(this.bus)
  }

  // FM electric-piano tone: a sine carrier rung by a sine modulator (bell-ish
  // attack that mellows into a pure tone). Sounds like a soft Rhodes.
  #epiano(midi, time, dur, gain = 0.07, pan = 0) {
    const freq = 440 * Math.pow(2, (midi - 69) / 12)
    const carrier = this.ctx.createOscillator(); carrier.type = "sine"; carrier.frequency.value = freq
    const mod = this.ctx.createOscillator(); mod.type = "sine"; mod.frequency.value = freq * 2
    const modGain = this.ctx.createGain()
    modGain.gain.setValueAtTime(freq * 1.4, time)
    modGain.gain.exponentialRampToValueAtTime(freq * 0.05, time + Math.min(dur, 0.8))
    mod.connect(modGain); modGain.connect(carrier.frequency)

    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.linearRampToValueAtTime(gain, time + 0.012)
    g.gain.exponentialRampToValueAtTime(0.0001, time + dur)

    const panner = this.ctx.createStereoPanner(); panner.pan.value = Math.max(-1, Math.min(1, pan))
    carrier.connect(g); g.connect(panner); panner.connect(this.bus)
    carrier.start(time); mod.start(time)
    carrier.stop(time + dur + 0.1); mod.stop(time + dur + 0.1)
  }

  #kick(time) {
    const osc = this.ctx.createOscillator()
    osc.frequency.setValueAtTime(150, time)
    osc.frequency.exponentialRampToValueAtTime(45, time + 0.11)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.0001, time)
    g.gain.linearRampToValueAtTime(0.55, time + 0.005)
    g.gain.exponentialRampToValueAtTime(0.0001, time + 0.22)
    osc.connect(g); g.connect(this.master) // dry, no reverb on the low end
    osc.start(time); osc.stop(time + 0.25)
  }

  #hat(time) {
    const noise = this.ctx.createBufferSource()
    noise.buffer = this.#noiseBuffer()
    const hp = this.ctx.createBiquadFilter(); hp.type = "highpass"; hp.frequency.value = 7000
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.08, time)
    g.gain.exponentialRampToValueAtTime(0.0001, time + 0.05)
    noise.connect(hp); hp.connect(g); g.connect(this.bus)
    noise.start(time); noise.stop(time + 0.06)
  }

  // --- helpers (built once, cached) -----------------------------------

  #saturationCurve(amount) {
    const n = 1024, curve = new Float32Array(n), k = amount * 12
    for (let i = 0; i < n; i++) {
      const x = (i * 2) / n - 1
      curve[i] = ((1 + k) * x) / (1 + k * Math.abs(x)) // soft clip
    }
    return curve
  }

  #impulseResponse(ctx, seconds, decay) {
    const rate = ctx.sampleRate, len = Math.floor(rate * seconds)
    const buf = ctx.createBuffer(2, len, rate)
    for (let ch = 0; ch < 2; ch++) {
      const data = buf.getChannelData(ch)
      let seed = ch + 1
      for (let i = 0; i < len; i++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff // deterministic PRNG
        const rand = seed / 0x7fffffff * 2 - 1
        data[i] = rand * Math.pow(1 - i / len, decay)
      }
    }
    return buf
  }

  #noiseBuffer() {
    if (this._noise) return this._noise
    const rate = this.ctx.sampleRate, len = Math.floor(rate * 0.2)
    const buf = this.ctx.createBuffer(1, len, rate)
    const data = buf.getChannelData(0)
    let seed = 7
    for (let i = 0; i < len; i++) { seed = (seed * 1103515245 + 12345) & 0x7fffffff; data[i] = seed / 0x7fffffff * 2 - 1 }
    this._noise = buf
    return buf
  }

  #reflect() {
    const playing = this.state.playing
    this.playIconTarget?.classList.toggle("hidden", playing)
    this.pauseIconTarget?.classList.toggle("hidden", !playing)
    this.vizTarget?.classList.toggle("is-playing", playing)
  }
}
