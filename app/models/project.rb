class Project < ApplicationRecord
  has_many :columns, -> { order(:position) }, dependent: :destroy
  has_many :issues, through: :columns

  validates :name, :key, :slug, presence: true
  validates :slug, :key, uniqueness: true

  # When an issue is reordered/moved, the project touch triggers a single
  # page-refresh broadcast that morphs the board for every connected client.
  broadcasts_refreshes

  def to_param = slug

  def next_issue_number
    with_lock do
      increment!(:issues_seq)
      issues_seq
    end
  end
end
