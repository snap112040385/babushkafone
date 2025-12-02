class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @reset_url = edit_password_url(user.generate_token_for(:password_reset))
    mail subject: "Восстановление пароля", to: user.email_address
  end
end
