# Spindle — a music player whose hero feature is that it keeps playing while you
# browse the whole app (data-turbo-permanent). Audio is *user-initiated* and
# genuinely musical: each track is a chord progression the synth_controller
# plays live with Web Audio — no audio files, no droning ambient loop.
module Spindle
  def self.table_name_prefix = "spindle_"

  def self.seed!
    return if Album.exists?

    night = Album.create!(title: "Night Shipping", slug: "night-shipping",
      artist: "The Hotwire Collective", mood: "Lo-fi keys for late deploys", hue: "#7c3aed", position: 0)
    night.tracks.create!([
      { title: "Morph & Chill",      position: 0, bpm: 78, texture: "keys",  roots: "57,53,60,55", duration_label: "3:12" },
      { title: "Permanent State",    position: 1, bpm: 72, texture: "pad",   roots: "53,57,60,62", duration_label: "4:05" },
      { title: "Frame Lazy",         position: 2, bpm: 90, texture: "pluck", roots: "60,55,57,52", duration_label: "2:48" },
      { title: "Solid Cable Groove", position: 3, bpm: 96, texture: "beat",  roots: "48,55,53,57", duration_label: "3:33" }
    ])

    drift = Album.create!(title: "Broadcast Drift", slug: "broadcast-drift",
      artist: "Idiomorph", mood: "Warm pads for the on-call hours", hue: "#0ea5e9", position: 1)
    drift.tracks.create!([
      { title: "Refresh, Quietly",  position: 0, bpm: 68, texture: "pad",   roots: "50,57,55,62", duration_label: "4:40" },
      { title: "Stream Append",     position: 1, bpm: 84, texture: "keys",  roots: "55,60,57,53", duration_label: "3:20" },
      { title: "Optimistic",        position: 2, bpm: 100, texture: "pluck", roots: "62,57,60,65", duration_label: "2:58" }
    ])
  end
end
