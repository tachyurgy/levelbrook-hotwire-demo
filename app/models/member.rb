class Member < ApplicationRecord
  has_many :assigned_issues, class_name: "Issue", foreign_key: :assignee_id, dependent: :nullify
  has_many :comments, dependent: :nullify

  validates :name, presence: true

  COLORS = %w[indigo emerald amber rose sky violet teal orange].freeze

  def initials
    name.split.map(&:first).first(2).join.upcase
  end
end
