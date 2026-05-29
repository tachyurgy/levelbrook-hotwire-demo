# A non-persisted form object used purely to demo server-rendered, per-field
# live validation. The validations here are the single source of truth — the
# client renders the very same model errors via Turbo Streams on blur.
class Signup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :workspace_name, :string
  attribute :subdomain, :string
  attribute :email, :string
  attribute :seats, :integer

  validates :workspace_name, presence: true, length: { minimum: 2, maximum: 40 }
  validates :subdomain, presence: true,
                        format: { with: /\A[a-z0-9-]+\z/, message: "lowercase letters, numbers and dashes only" },
                        length: { minimum: 3, maximum: 30 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }
  validates :seats, numericality: { greater_than: 0, less_than_or_equal_to: 500 }

  validate :subdomain_available

  RESERVED = %w[admin api www app support help blog].freeze

  def subdomain_available
    return if subdomain.blank?
    errors.add(:subdomain, "is already taken") if RESERVED.include?(subdomain.downcase)
  end
end
