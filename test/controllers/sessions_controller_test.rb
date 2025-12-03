require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials and confirmed email" do
    @user.confirm_email!

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to "/dashboard"
    assert cookies[:session_id]
  end

  test "create with valid credentials but unconfirmed email" do
    assert_not @user.email_confirmed

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    assert_equal "Пожалуйста, подтвердите ваш email перед входом. Проверьте почту или запросите новое письмо подтверждения.", flash[:alert]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    # А здесь при выходе обычно кидает на главную
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
