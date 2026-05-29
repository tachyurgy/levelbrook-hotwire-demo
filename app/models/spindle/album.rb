class Spindle::Album < ApplicationRecord
  has_many :tracks, -> { order(:position) }, dependent: :destroy

  validates :title, :slug, :artist, presence: true

  def to_param = slug
end
