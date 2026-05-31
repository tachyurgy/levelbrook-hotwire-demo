# Spindle — a music player whose hero feature is that it keeps playing while you
# browse the whole app (data-turbo-permanent). It demonstrates two playback paths:
#
#   * "synth" albums  — NO audio files. Every note is generated live in the
#     browser by the Web Audio API (synth_controller.js) from a chord
#     progression. The point is the engineering, not the fidelity.
#   * "stream" albums — real CC0 / public-domain recordings served from
#     /public/spindle (see public/spindle/CREDITS.md). Same persistent player.
#
# Audio is always user-initiated; nothing ever auto-plays.
module Spindle
  def self.table_name_prefix = "spindle_"

  def self.seed!
    return if Album.exists?

    # --- Live-synthesized (no files — rendered in the browser) ---------------
    night = Album.create!(title: "Night Shipping", slug: "night-shipping", kind: "synth",
      artist: "The Hotwire Collective", mood: "Synthesized live — lo-fi keys for late deploys", hue: "#7c3aed", position: 0)
    night.tracks.create!([
      { title: "Morph & Chill",      position: 0, bpm: 78, texture: "keys",  roots: "57,53,60,55", duration_label: "3:12" },
      { title: "Permanent State",    position: 1, bpm: 72, texture: "pad",   roots: "53,57,60,62", duration_label: "4:05" },
      { title: "Frame Lazy",         position: 2, bpm: 90, texture: "pluck", roots: "60,55,57,52", duration_label: "2:48" },
      { title: "Solid Cable Groove", position: 3, bpm: 96, texture: "beat",  roots: "48,55,53,57", duration_label: "3:33" }
    ])

    drift = Album.create!(title: "Broadcast Drift", slug: "broadcast-drift", kind: "synth",
      artist: "Idiomorph", mood: "Synthesized live — warm pads for the on-call hours", hue: "#0ea5e9", position: 1)
    drift.tracks.create!([
      { title: "Refresh, Quietly",  position: 0, bpm: 68,  texture: "pad",   roots: "50,57,55,62", duration_label: "4:40" },
      { title: "Stream Append",     position: 1, bpm: 84,  texture: "keys",  roots: "55,60,57,53", duration_label: "3:20" },
      { title: "Optimistic",        position: 2, bpm: 100, texture: "pluck", roots: "62,57,60,65", duration_label: "2:58" }
    ])

    # --- Real CC0 recordings (public domain — streamed from /public/spindle) -
    lofi = Album.create!(title: "Public Domain Tape", slug: "public-domain-tape", kind: "stream",
      artist: "Rick Hoppmann", mood: "Real CC0 lo-fi loops — no attribution required", hue: "#d97706", position: 2)
    lofi.tracks.create!([
      { title: "Deep Humidity",                position: 0, audio_url: "/spindle/deep-humidity.mp3",      duration_label: "2:11" },
      { title: "Honey Bear",                   position: 1, audio_url: "/spindle/honey-bear.mp3",         duration_label: "1:20" },
      { title: "Everything Is Gonna Be Alright", position: 2, audio_url: "/spindle/everything-alright.mp3", duration_label: "1:25" }
    ])

    signal = Album.create!(title: "Free Signal", slug: "free-signal", kind: "stream",
      artist: "Alexander Ehlers", mood: "Real CC0 cinematic electronic — public domain", hue: "#059669", position: 3)
    signal.tracks.create!([
      { title: "Spacetime",     position: 0, audio_url: "/spindle/spacetime.mp3",    duration_label: "1:56" },
      { title: "Warped",        position: 1, audio_url: "/spindle/warped.mp3",       duration_label: "1:54" },
      { title: "Twists",        position: 2, audio_url: "/spindle/twists.mp3",       duration_label: "3:00" },
      { title: "Great Mission", position: 3, audio_url: "/spindle/greatmission.mp3", duration_label: "1:59" }
    ])
  end
end
