require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and send confirmation email" do
    assert_difference("User.count") do
      post registration_path, params: { user: { email_address: "newuser@example.com", password: "password123", password_confirmation: "password123" } }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_not user.email_confirmed
    assert_redirected_to new_session_path
    assert_equal "Регистрация успешна! Проверьте вашу почту для подтверждения email.", flash[:notice]

    assert_emails 1
  end

  test "should not create user with invalid data" do
    assert_no_difference("User.count") do
      post registration_path, params: { user: { email_address: "", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_entity
  end
end
