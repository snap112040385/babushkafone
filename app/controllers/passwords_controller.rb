class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Попробуйте позже." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      # В production используется deliver_later для асинхронной отправки
      # В development deliver_now для немедленной отправки и отладки
      if Rails.env.production?
        PasswordsMailer.reset(user).deliver_later
      else
        PasswordsMailer.reset(user).deliver_now
      end
    end

    redirect_to new_session_path, notice: "Инструкции по восстановлению пароля отправлены на email (если пользователь с таким адресом существует)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Пароль успешно изменен."
    else
      redirect_to edit_password_path(params[:token]), alert: "Пароли не совпадают или не соответствуют требованиям."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for!(:password_reset, params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Ссылка для сброса пароля недействительна или устарела."
    end
end
