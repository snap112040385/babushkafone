require "test_helper"

class ConfirmationsMailerTest < ActionMailer::TestCase
  test "confirmation_email" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    mail = ConfirmationsMailer.confirmation_email(user)

    assert_equal "Подтверждение email для Бабушкафон", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_match "Добро пожаловать", mail.text_part.decoded
    assert_match "Подтвердить email", mail.html_part.decoded
  end
end
