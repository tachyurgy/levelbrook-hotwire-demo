class Spindle::Track < ApplicationRecord
  belongs_to :album

  validates :title, presence: true
  # Live-synth tracks need a chord progression; file-backed tracks need a URL.
  validates :roots, presence: true, unless: :file_backed?
  validates :audio_url, presence: true, if: -> { roots.blank? }

  def file_backed? = audio_url.present?

  # The payload the persistent player needs to play this track. For file-backed
  # tracks the player just streams `audioUrl`; otherwise the synth engine
  # renders it live from `roots`/`texture`.
  def play_payload
    {
      id: id,
      title: title,
      album: album.title,
      artist: album.artist,
      hue: album.hue,
      audioUrl: audio_url,
      bpm: bpm,
      texture: texture,
      roots: roots.to_s.split(",").map(&:to_i),
      duration: duration_label
    }
  end
end
