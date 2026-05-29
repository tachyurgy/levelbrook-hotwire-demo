class Comment < ApplicationRecord
  belongs_to :issue
  belongs_to :member, optional: true

  validates :body, presence: true

  # Surgical append to the open issue-detail thread for every viewer of it.
  after_create_commit do
    broadcast_append_to issue,
      target: ActionView::RecordIdentifier.dom_id(issue, :comments),
      partial: "comments/comment"
  end
end
