class ConfirmationsMailer < ApplicationMailer
  def confirmation_email(user)
    @user = user
    @confirmation_url = edit_email_confirmation_url(user.generate_token_for(:email_confirmation))

    mail subject: "Подтверждение email для Бабушкафон", to: user.email_address
  end
end
