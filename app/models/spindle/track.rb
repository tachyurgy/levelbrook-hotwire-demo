class Spindle::Track < ApplicationRecord
  belongs_to :album

  validates :title, :roots, presence: true

  # The payload the persistent player needs to synthesize this track live.
  def play_payload
    {
      id: id,
      title: title,
      album: album.title,
      artist: album.artist,
      hue: album.hue,
      bpm: bpm,
      texture: texture,
      roots: roots.split(",").map(&:to_i),
      duration: duration_label
    }
  end
end
