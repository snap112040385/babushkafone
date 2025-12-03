class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      unless user.confirmed?
        redirect_to new_session_path, alert: "Пожалуйста, подтвердите ваш email перед входом. Проверьте почту или запросите новое письмо подтверждения."
        return
      end

      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Вы успешно вышли из системы", status: :see_other
  end
end
