class Spindle::Album < ApplicationRecord
  has_many :tracks, -> { order(:position) }, dependent: :destroy

  validates :title, :slug, :artist, presence: true

  # "synth" = every note generated live in the browser (Web Audio, no files).
  # "stream" = real CC0 / public-domain recordings served from /public/spindle.
  def synth?  = kind == "synth"
  def stream? = kind == "stream"

  def to_param = slug
end
