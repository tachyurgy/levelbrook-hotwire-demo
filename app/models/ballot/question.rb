class Ballot::Question < ApplicationRecord
  belongs_to :room, touch: true

  validates :body, :author, presence: true
end
