require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should confirm email with valid token" do
    token = @user.generate_token_for(:email_confirmation)

    assert_not @user.email_confirmed

    get edit_email_confirmation_path(token: token)

    @user.reload
    assert @user.email_confirmed
    assert_not_nil @user.email_confirmed_at
    assert_redirected_to new_session_path
    assert_equal "Email успешно подтвержден! Теперь вы можете войти в систему.", flash[:notice]
  end

  test "should not confirm email with invalid token" do
    get edit_email_confirmation_path(token: "invalid_token")

    @user.reload
    assert_not @user.email_confirmed
    assert_redirected_to new_session_path
    assert_equal "Ссылка для подтверждения email недействительна или устарела.", flash[:alert]
  end

  test "should resend confirmation email" do
    assert_emails 1 do
      post email_confirmation_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_session_path
  end

  test "should not send email if user already confirmed" do
    @user.confirm_email!

    assert_no_emails do
      post email_confirmation_path, params: { email_address: @user.email_address }
    end
  end
end
