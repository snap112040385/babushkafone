class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Попробуйте позже." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      unless user.confirmed?
        begin
          if Rails.env.production?
            Rails.logger.info "Отправка письма подтверждения для #{user.email_address}"
            ConfirmationsMailer.confirmation_email(user).deliver_later
            Rails.logger.info "Письмо добавлено в очередь Solid Queue"
          else
            ConfirmationsMailer.confirmation_email(user).deliver_now
          end
        rescue => e
          Rails.logger.error "Ошибка при отправке письма: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end

    redirect_to new_session_path, notice: "Инструкции по подтверждению email отправлены на указанный адрес (если такой пользователь существует и email еще не подтвержден)."
  end

  def edit
    if @user.confirm_email!
      redirect_to new_session_path, notice: "Email успешно подтвержден! Теперь вы можете войти в систему."
    else
      redirect_to new_session_path, alert: "Не удалось подтвердить email."
    end
  end

  private
    def set_user_by_token
      Rails.logger.info "Attempting email confirmation with token: #{params[:token]&.first(50)}..."
      @user = User.find_by_token_for!(:email_confirmation, params[:token])
      Rails.logger.info "Successfully found user: #{@user.email_address}"
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      Rails.logger.error "Invalid token signature: #{e.message}"
      redirect_to new_session_path, alert: "Ссылка для подтверждения email недействительна или устарела."
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "User not found or token expired: #{e.message}"
      redirect_to new_session_path, alert: "Ссылка для подтверждения email недействительна или устарела."
    rescue => e
      Rails.logger.error "Unexpected error during email confirmation: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      redirect_to new_session_path, alert: "Ссылка для подтверждения email недействительна или устарела."
    end
end
