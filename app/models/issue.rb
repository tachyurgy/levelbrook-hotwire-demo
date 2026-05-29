class Issue < ApplicationRecord
  belongs_to :column, touch: true
  belongs_to :assignee, class_name: "Member", optional: true
  has_many :comments, -> { order(:created_at) }, dependent: :destroy

  before_validation :assign_number, on: :create

  validates :title, presence: true
  validates :number, presence: true
  validates :label, inclusion: { in: %w[feature bug chore design] }
  validates :priority, inclusion: { in: %w[urgent high medium low] }
  validates :points, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 21 }

  LABEL_COLORS = {
    "feature" => "emerald",
    "bug"     => "rose",
    "chore"   => "slate",
    "design"  => "violet"
  }.freeze

  PRIORITY_RANK = { "urgent" => 0, "high" => 1, "medium" => 2, "low" => 3 }.freeze

  delegate :project, to: :column

  def key
    "#{project.key}-#{number}"
  end

  def label_color = LABEL_COLORS.fetch(label, "slate")

  private

  def assign_number
    self.number ||= column&.project&.next_issue_number
  end
end
