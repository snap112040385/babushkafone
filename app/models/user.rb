class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?

  generates_token_for :password_reset, expires_in: 2.hours
  generates_token_for :email_confirmation, expires_in: 24.hours do
    email_confirmed_at
  end

  scope :confirmed, -> { where(email_confirmed: true) }
  scope :unconfirmed, -> { where(email_confirmed: false) }

  def confirm_email!
    update!(email_confirmed: true, email_confirmed_at: Time.current)
  end

  def confirmed?
    email_confirmed
  end
end
