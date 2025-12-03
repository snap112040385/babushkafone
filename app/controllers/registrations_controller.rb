class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      begin
        if Rails.env.production?
          Rails.logger.info "Отправка письма подтверждения для #{@user.email_address}"
          ConfirmationsMailer.confirmation_email(@user).deliver_later
          Rails.logger.info "Письмо добавлено в очередь Solid Queue"
        else
          ConfirmationsMailer.confirmation_email(@user).deliver_now
        end
      rescue => e
        Rails.logger.error "Ошибка при отправке письма: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end

      redirect_to new_session_path, notice: "Регистрация успешна! Проверьте вашу почту для подтверждения email."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
