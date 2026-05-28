class Story < ApplicationRecord
  has_many :scenes, dependent: :destroy
  has_many :choices, through: :scenes

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug

  def opening_scene
    scenes.find_by(key: "start") || scenes.order(:id).first
  end

  def scene(key)
    scenes.find_by!(key: key)
  end
end
