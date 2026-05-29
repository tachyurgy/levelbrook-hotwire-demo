class Channel < ApplicationRecord
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  def to_param = slug
end
