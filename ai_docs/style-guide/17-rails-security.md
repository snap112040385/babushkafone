# Rails Security - Безопасность

## Основные принципы

### Защита от основных уязвимостей
- **SQL Injection** - используйте параметризованные запросы
- **XSS (Cross-Site Scripting)** - экранируйте вывод
- **CSRF (Cross-Site Request Forgery)** - используйте токены
- **Mass Assignment** - используйте Strong Parameters
- **Session Fixation** - сбрасывайте сессии
- **Timing Attacks** - используйте безопасные сравнения

## Конфигурация безопасности

### config/application.rb
```ruby
module MyApp
  class Application < Rails::Application
    # Включить все security заголовки
    config.force_ssl = true
    
    # Content Security Policy
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.font_src    :self, :https, :data
      policy.img_src     :self, :https, :data
      policy.object_src  :none
      policy.script_src  :self, :https
      policy.style_src   :self, :https, :unsafe_inline
      policy.connect_src :self, :https, 'http://localhost:3035', 'ws://localhost:3035' if Rails.env.development?
    end
    
    # Разрешить inline scripts с nonce
    config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
    config.content_security_policy_nonce_directives = %w[script-src style-src]
    
    # Security headers
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-Content-Type-Options' => 'nosniff',
      'X-XSS-Protection' => '1; mode=block',
      'X-Download-Options' => 'noopen',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Referrer-Policy' => 'strict-origin-when-cross-origin'
    }
  end
end
```

## SQL Injection защита

### Безопасные запросы
```ruby
# ✅ ПРАВИЛЬНО - параметризованные запросы
User.where(name: params[:name])
User.where("name = ?", params[:name])
User.where("name = :name", name: params[:name])
User.find_by(email: params[:email])

# ❌ ОПАСНО - прямая интерполяция
User.where("name = '#{params[:name]}'")
User.where("id = #{params[:id]}")

# ✅ Безопасное использование LIKE
term = "%#{sanitize_sql_like(params[:search])}%"
User.where("name LIKE ?", term)

# ✅ Безопасный ORDER BY
safe_columns = %w[name created_at email]
order_column = safe_columns.include?(params[:sort]) ? params[:sort] : 'created_at'
direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
User.order("#{order_column} #{direction}")

# ✅ Безопасное использование pluck/select
allowed_columns = %w[id name email]
columns = params[:columns].select { |col| allowed_columns.include?(col) }
User.select(columns)
```

### Использование Arel для сложных запросов
```ruby
# ✅ Безопасно с Arel
users = User.arel_table
User.where(users[:age].gt(18).and(users[:name].matches("%#{term}%")))

# Безопасный raw SQL когда необходимо
User.find_by_sql([
  "SELECT * FROM users WHERE department_id = ? AND active = ?",
  params[:department_id], true
])
```

## XSS защита

### Экранирование вывода
```erb
<!-- ✅ ПРАВИЛЬНО - автоматическое экранирование -->
<%= @user.name %>
<%= link_to @user.bio, user_path(@user) %>

<!-- ❌ ОПАСНО - raw вывод -->
<%== @user.input %>
<%= raw(@user.input) %>
<%= @user.input.html_safe %>

<!-- ✅ Безопасный вывод HTML -->
<%= sanitize(@user.bio, tags: %w[p br strong em], attributes: %w[class]) %>
<%= simple_format(@user.description) %>

<!-- ✅ Экранирование в JavaScript -->
<script>
  var userName = <%= json_escape(@user.name.to_json).html_safe %>;
  var userId = <%= @user.id.to_json.html_safe %>;
</script>

<!-- Или используйте data-атрибуты -->
<div data-user-name="<%= @user.name %>" 
     data-user-id="<%= @user.id %>">
</div>
```

### Content Security Policy
```ruby
# Для конкретных actions
class ApplicationController < ActionController::Base
  content_security_policy do |policy|
    policy.script_src :self, :https, :unsafe_inline if action_name == 'special'
  end
end
```

## CSRF защита

### Включение CSRF защиты
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Для API - null session
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
end
```

### CSRF токены в формах
```erb
<!-- Автоматически добавляется в form_with -->
<%= form_with model: @user do |f| %>
  <!-- csrf_token включен -->
<% end %>

<!-- Для AJAX запросов -->
<meta name="csrf-token" content="<%= form_authenticity_token %>">

<script>
  fetch('/api/data', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });
</script>
```

## Strong Parameters

### Правильное использование
```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    # ...
  end
  
  private
  
  def user_params
    # ✅ Явный whitelist параметров
    params.require(:user).permit(:name, :email, :password)
  end
  
  def admin_user_params
    # ✅ Условные параметры для админов
    if current_user.admin?
      params.require(:user).permit(:name, :email, :role, :salary)
    else
      user_params
    end
  end
end

# ❌ НИКОГДА не делайте так
def user_params
  params.require(:user).permit!  # Разрешает все параметры!
end
```

## Аутентификация

### Devise конфигурация
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # Безопасные настройки
  config.password_length = 8..128
  config.timeout_in = 30.minutes
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 5
  config.unlock_strategy = :both
  config.unlock_in = 1.hour
  
  # Session security
  config.expire_all_remember_me_on_sign_out = true
  config.session_limitable = true
  
  # Password security
  config.paranoid = true
  config.stretches = Rails.env.test? ? 1 : 12
  
  # Email security
  config.reconfirmable = true
  config.confirmation_keys = [:email]
end
```

### Кастомная аутентификация
```ruby
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email].downcase)
    
    # ✅ Rate limiting
    if too_many_attempts?(params[:email])
      render json: { error: 'Too many attempts' }, status: :too_many_requests
      return
    end
    
    # ✅ Безопасная проверка пароля (защита от timing attacks)
    if user&.authenticate(params[:password])
      # ✅ Сброс session fixation
      reset_session
      
      session[:user_id] = user.id
      user.regenerate_auth_token
      
      redirect_to root_path
    else
      # ✅ Generic error message
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def too_many_attempts?(email)
    key = "login_attempts:#{email}"
    attempts = Rails.cache.increment(key, 1, expires_in: 1.hour)
    attempts > 5
  end
end
```

## Авторизация

### Pundit policies
```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def show?
    user == record || user.admin?
  end
  
  def update?
    user == record || user.admin?
  end
  
  def destroy?
    user.admin? && user != record
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(organization: user.organization)
      end
    end
  end
end

# В контроллере
class UsersController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized
  
  def show
    @user = User.find(params[:id])
    authorize @user
  end
  
  def index
    @users = policy_scope(User)
  end
end
```

## Шифрование данных

### Шифрование атрибутов
```ruby
class User < ApplicationRecord
  # Rails 7+ encryption
  encrypts :ssn, deterministic: true
  encrypts :api_key
  
  # Кастомное шифрование
  attr_encrypted :credit_card_number,
                 key: Rails.application.credentials.encryption_key,
                 algorithm: 'aes-256-gcm'
end

# config/application.rb
config.active_record.encryption.primary_key = Rails.application.credentials.active_record_encryption.primary_key
config.active_record.encryption.deterministic_key = Rails.application.credentials.active_record_encryption.deterministic_key
config.active_record.encryption.key_derivation_salt = Rails.application.credentials.active_record_encryption.key_derivation_salt
```

## Безопасная работа с файлами

### Загрузка файлов
```ruby
class DocumentsController < ApplicationController
  def create
    # ✅ Проверка типа файла
    file = params[:file]
    
    unless allowed_file_type?(file)
      redirect_to root_path, alert: 'Invalid file type'
      return
    end
    
    # ✅ Проверка размера
    if file.size > 10.megabytes
      redirect_to root_path, alert: 'File too large'
      return
    end
    
    # ✅ Сканирование на вирусы
    if virus_detected?(file)
      redirect_to root_path, alert: 'Security threat detected'
      return
    end
    
    # ✅ Сохранение с безопасным именем
    filename = sanitize_filename(file.original_filename)
    @document = Document.create(file: file, name: filename)
  end
  
  private
  
  def allowed_file_type?(file)
    allowed_types = %w[image/jpeg image/png application/pdf]
    allowed_types.include?(file.content_type) &&
      allowed_types.include?(Marcel::MimeType.for(file))
  end
  
  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z.\-]/, '_')
  end
  
  def virus_detected?(file)
    # Интеграция с антивирусом
    ClamScan.scan(file.path).infected?
  rescue => e
    Rails.logger.error "Virus scan failed: #{e.message}"
    true # Безопаснее считать зараженным
  end
end
```

## Secrets и Credentials

### Использование credentials
```ruby
# Редактирование
# rails credentials:edit --environment production

# config/credentials/production.yml.enc
secret_key_base: xxx
database:
  password: xxx
api:
  stripe:
    secret_key: xxx
    webhook_secret: xxx
  aws:
    access_key_id: xxx
    secret_access_key: xxx

# Использование в коде
Rails.application.credentials.api[:stripe][:secret_key]
Rails.application.credentials.dig(:api, :stripe, :secret_key)

# Проверка наличия
if Rails.application.credentials.api&.dig(:stripe, :secret_key).present?
  # Использовать Stripe
end
```

## Headers безопасности

### Rack middleware
```ruby
# config/application.rb
config.middleware.use Rack::Attack

# config/initializers/rack_attack.rb
Rack::Attack.throttle('req/ip', limit: 100, period: 1.minute) do |req|
  req.ip
end

Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  if req.path == '/login' && req.post?
    req.ip
  end
end

Rack::Attack.blocklist('bad-robots') do |req|
  req.user_agent =~ /BadBot|EvilCrawler/i
end
```

## Логирование и мониторинг

### Безопасное логирование
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :token, :api_key, :secret,
  :credit_card_number, :cvv, :ssn,
  :otp_secret, :otp_code
]

# Кастомная фильтрация
Rails.application.config.filter_parameters << lambda do |key, value|
  value.replace('[FILTERED]') if key.match?(/secret|token|key/i)
end

# Логирование безопасности
class SecurityLogger
  def self.log_auth_attempt(user, success:, ip:)
    Rails.logger.info({
      event: 'authentication_attempt',
      user_id: user&.id,
      email: user&.email,
      success: success,
      ip: ip,
      timestamp: Time.current
    }.to_json)
  end
end
```

## Рекомендации для Claude Code

1. **Никогда не доверяйте пользовательскому вводу**
2. **Используйте параметризованные запросы**
3. **Экранируйте весь вывод**
4. **Применяйте принцип наименьших привилегий**
5. **Регулярно обновляйте зависимости**
6. **Логируйте события безопасности**
7. **Используйте HTTPS везде**
