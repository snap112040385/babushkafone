# Preview all emails at http://localhost:3000/rails/mailers/confirmations_mailer
class ConfirmationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/confirmations_mailer/confirmation_email
  def confirmation_email
    ConfirmationsMailer.confirmation_email
  end
end
