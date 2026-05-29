class Column < ApplicationRecord
  belongs_to :project, touch: true
  has_many :issues, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true

  def over_wip_limit?
    wip_limit.present? && issues.size > wip_limit
  end
end
