require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
  end

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    # В тестовом окружении письма отправляются синхронно
    assert_emails 1 do
      post passwords_path, params: { email_address: @user.email_address }
    end
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "Инструкции по восстановлению пароля отправлены на email"
  end

  test "create for an unknown user redirects but sends no mail" do
    assert_no_emails do
      post passwords_path, params: { email_address: "missing-user@example.com" }
    end
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "Инструкции по восстановлению пароля отправлены на email"
  end

  test "edit" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_path(token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid-token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "Ссылка для сброса пароля недействительна или устарела"
  end

  test "update" do
    token = @user.generate_token_for(:password_reset)

    assert_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Пароль успешно изменен"
  end

  test "update with non matching passwords" do
    token = @user.generate_token_for(:password_reset)

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Пароли не совпадают"
  end

  test "update with expired token" do
    token = @user.generate_token_for(:password_reset)

    # Имитация истечения токена путем перемещения времени вперед
    travel 3.hours do
      assert_no_changes -> { @user.reload.password_digest } do
        put password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        assert_redirected_to new_password_path
      end

      follow_redirect!
      assert_notice "Ссылка для сброса пароля недействительна или устарела"
    end
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
