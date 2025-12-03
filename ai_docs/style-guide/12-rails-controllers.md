# Rails Controllers - Контроллеры и Action Controller

## Структура контроллера

### RESTful контроллер
```ruby
class UsersController < ApplicationController
  # Filters в правильном порядке
  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authorize_user!, only: %i[edit update destroy]
  
  # GET /users
  def index
    @users = User.includes(:profile)
                 .page(params[:page])
                 .per(20)
  end
  
  # GET /users/1
  def show
    @posts = @user.posts.recent.limit(10)
  end
  
  # GET /users/new
  def new
    @user = User.new
  end
  
  # GET /users/1/edit
  def edit
  end
  
  # POST /users
  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to @user, notice: 'Пользователь успешно создан.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'Пользователь успешно обновлен.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /users/1
  def destroy
    @user.destroy!
    redirect_to users_url, notice: 'Пользователь успешно удален.',
                            status: :see_other
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
  
  def authorize_user!
    redirect_to root_path, alert: 'Недостаточно прав' unless can?(:manage, @user)
  end
end
```

## Наследование контроллеров

### ApplicationController
```ruby
class ApplicationController < ActionController::Base
  # Rails 8 security defaults
  protect_from_forgery with: :exception
  
  # Общие concerns
  include Authentication
  include Authorization
  include ErrorHandling
  
  # Глобальные before_action
  before_action :set_locale
  before_action :track_user_activity
  
  # Helpers доступные во views
  helper_method :current_user, :logged_in?
  
  private
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  
  def track_user_activity
    Current.user = current_user
    Current.request_id = request.request_id
  end
end
```

### Namespace контроллеры
```ruby
# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :require_admin!
    
    layout 'admin'
    
    private
    
    def require_admin!
      redirect_to root_path unless current_user&.admin?
    end
  end
end

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < BaseController
    # наследует require_admin! и layout
  end
end
```

## API контроллеры

### API base controller
```ruby
module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      
      before_action :authenticate!
      
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
      def authenticate!
        authenticate_or_request_with_http_token do |token, options|
          @current_user = User.find_by(api_token: token)
        end
      end
      
      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: { 
          error: 'Validation failed',
          errors: exception.record.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end
  end
end
```

### API controller с JSON responses
```ruby
module Api
  module V1
    class UsersController < BaseController
      def index
        users = User.page(params[:page]).per(params[:per_page] || 20)
        
        render json: {
          users: users.as_json(only: [:id, :name, :email]),
          meta: {
            current_page: users.current_page,
            total_pages: users.total_pages,
            total_count: users.total_count
          }
        }
      end
      
      def show
        user = User.find(params[:id])
        render json: user, serializer: UserSerializer
      end
      
      def create
        user = User.new(user_params)
        
        if user.save
          render json: user, status: :created
        else
          render json: { errors: user.errors }, 
                 status: :unprocessable_entity
        end
      end
    end
  end
end
```

## Strong Parameters

### Базовое использование
```ruby
class UsersController < ApplicationController
  private
  
  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :avatar,
      role: [],  # массив
      profile_attributes: [:bio, :website, :location],  # вложенные атрибуты
      preferences: {}  # произвольный хеш
    )
  end
end
```

### Условные параметры
```ruby
def user_params
  allowed = [:name, :email]
  allowed << :role if current_user.admin?
  allowed << :salary if can?(:manage_salary, User)
  
  params.require(:user).permit(allowed)
end
```

### Обработка массивов и хешей
```ruby
def product_params
  params.require(:product).permit(
    :name,
    :price,
    category_ids: [],  # массив ID
    tags: [],          # массив строк
    metadata: {},      # произвольный хеш
    # вложенные формы
    variants_attributes: [
      :id,
      :size,
      :color,
      :price,
      :_destroy  # для удаления через accepts_nested_attributes_for
    ]
  )
end
```

## Filters (Callbacks)

### Before/After/Around actions
```ruby
class ApplicationController < ActionController::Base
  # Выполняется перед action
  before_action :require_login
  
  # Только для определенных actions
  before_action :set_resource, only: [:show, :edit, :update, :destroy]
  
  # Исключая определенные actions
  before_action :check_permission, except: [:index, :show]
  
  # После action
  after_action :log_activity
  
  # Вокруг action
  around_action :with_timezone
  
  private
  
  def with_timezone
    Time.use_zone(current_user.timezone) { yield }
  end
end
```

### Пропуск filters
```ruby
class PublicController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
end
```

## Respond формат

### respond_to для разных форматов
```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @product }
      format.pdf { render pdf: generate_pdf }
      format.any { head :not_acceptable }
    end
  end
end
```

### Turbo Stream responses (Rails 7+)
```ruby
class CommentsController < ApplicationController
  def create
    @comment = @post.comments.build(comment_params)
    
    if @comment.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append('comments', 
              partial: 'comments/comment',
              locals: { comment: @comment }),
            turbo_stream.update('comment_form',
              partial: 'comments/form',
              locals: { comment: Comment.new })
          ]
        end
        format.html { redirect_to @post }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Обработка ошибок

### rescue_from
```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  
  private
  
  def not_found
    respond_to do |format|
      format.html { render file: 'public/404.html', status: :not_found }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end
  
  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
  
  def forbidden
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Access denied' }
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end
end
```

## Concerns

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_user!
    helper_method :current_user, :logged_in?
  end
  
  private
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    current_user.present?
  end
  
  def authenticate_user!
    redirect_to login_path unless logged_in?
  end
end

# Использование
class ApplicationController < ActionController::Base
  include Authenticatable
end
```

## Редиректы и рендеринг

### Правильные статус коды
```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      # 302 Found (default)
      redirect_to @user, notice: 'Success'
    else
      # 422 Unprocessable Entity
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.destroy!
    # 303 See Other для Turbo
    redirect_to users_path, status: :see_other
  end
end
```

### Flash сообщения
```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate(params[:email], params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Успешный вход'
    else
      flash.now[:alert] = 'Неверный email или пароль'
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: 'Вы вышли из системы'
  end
end
```

## Streaming и загрузки

### Отправка файлов
```ruby
class DocumentsController < ApplicationController
  def download
    document = Document.find(params[:id])
    
    # Отправка файла с диска
    send_file document.file_path,
              filename: document.filename,
              type: document.content_type,
              disposition: 'attachment'  # или 'inline' для просмотра
    
    # Отправка данных
    send_data generate_pdf,
              filename: 'report.pdf',
              type: 'application/pdf'
  end
end
```

### Streaming responses
```ruby
class ReportsController < ApplicationController
  include ActionController::Live
  
  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    
    sse = SSE.new(response.stream, retry: 300)
    
    begin
      10.times do |i|
        sse.write({ progress: i * 10 }, event: 'progress')
        sleep 1
      end
    ensure
      sse.close
    end
  end
end
```

## Rate Limiting (Rails 8+)

```ruby
class ApiController < ApplicationController
  # Rails 8 встроенный rate limiting
  rate_limit to: 10, within: 1.minute, 
             by: -> { current_user&.id || request.remote_ip },
             with: -> { head :too_many_requests }
end
```

## Рекомендации для Claude Code

1. **Тонкие контроллеры** - логика в моделях и сервисах
2. **RESTful роуты** - следуйте конвенциям REST
3. **Strong Parameters** - всегда фильтруйте параметры
4. **Правильные статусы** - используйте семантические HTTP статусы
5. **DRY с concerns** - выносите общую логику в concerns
