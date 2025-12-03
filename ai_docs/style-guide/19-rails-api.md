# Rails API - API и JSON

## API-only приложение

### Создание API приложения
```bash
rails new myapp --api --database=postgresql
```

### ApplicationController для API
```ruby
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  # Обработка ошибок
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  # Rate limiting (Rails 8)
  rate_limit to: 100, within: 1.minute, 
             by: -> { request.remote_ip },
             with: -> { render_too_many_requests }
  
  before_action :authenticate!
  around_action :set_locale
  
  private
  
  def authenticate!
    authenticate_or_request_with_http_token do |token, options|
      @current_user = User.find_by(api_token: token)
      @current_user&.active?
    end
  end
  
  def current_user
    @current_user
  end
  
  def not_found(exception)
    render json: { 
      error: 'Resource not found',
      message: exception.message 
    }, status: :not_found
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      errors: exception.record.errors.as_json
    }, status: :unprocessable_entity
  end
  
  def bad_request(exception)
    render json: { 
      error: 'Bad request',
      message: exception.message 
    }, status: :bad_request
  end
  
  def render_too_many_requests
    render json: { 
      error: 'Too many requests',
      retry_after: 60 
    }, status: :too_many_requests
  end
  
  def set_locale(&block)
    locale = request.headers['Accept-Language']&.split(',')&.first || 'en'
    I18n.with_locale(locale, &block)
  end
end
```

## Версионирование API

### URL Path версионирование
```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users do
        resources :posts
      end
      resources :comments
    end
    
    namespace :v2 do
      resources :users do
        resources :posts
        resources :followers
      end
      resources :comments
      resources :reactions
    end
  end
end
```

### Header версионирование
```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    scope module: :v1, constraints: ApiVersion.new('v1') do
      resources :users
    end
    
    scope module: :v2, constraints: ApiVersion.new('v2', default: true) do
      resources :users
    end
  end
end

# app/constraints/api_version.rb
class ApiVersion
  def initialize(version, default = false)
    @version = version
    @default = default
  end
  
  def matches?(request)
    @default || request.headers['Accept']&.include?("application/vnd.myapi.#{@version}+json")
  end
end
```

## Serialization

### Active Model Serializers
```ruby
# Gemfile
gem 'active_model_serializers'

# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :created_at
  
  # Условные атрибуты
  attribute :admin, if: :current_user_is_admin?
  attribute :phone, unless: :guest_user?
  
  # Вычисляемые поля
  attribute :full_name do
    "#{object.first_name} #{object.last_name}"
  end
  
  # Ассоциации
  has_many :posts
  has_one :profile
  belongs_to :organization
  
  # URL helpers
  link(:self) { api_v1_user_url(object) }
  
  private
  
  def current_user_is_admin?
    current_user&.admin?
  end
  
  def guest_user?
    current_user.nil?
  end
end

# app/serializers/post_serializer.rb
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :published_at
  
  belongs_to :user
  has_many :comments
  
  # Кастомное имя ассоциации
  belongs_to :user, key: :author
  
  # Meta информация
  meta do
    { total_views: object.views_count }
  end
end
```

### JSONAPI спецификация
```ruby
# Gemfile
gem 'jsonapi-serializer'

# app/serializers/user_serializer.rb
class UserSerializer
  include JSONAPI::Serializer
  
  set_type :user
  set_id :uuid
  
  attributes :name, :email, :created_at
  
  attribute :active do |user|
    user.active?
  end
  
  has_many :posts
  has_one :profile
  
  meta do |user|
    { posts_count: user.posts.count }
  end
  
  link :self do |user|
    "/api/v1/users/#{user.id}"
  end
end

# Использование в контроллере
class Api::V1::UsersController < ApplicationController
  def index
    users = User.includes(:posts).page(params[:page])
    
    options = {
      include: [:posts, :profile],
      meta: { total: users.total_count },
      links: {
        self: request.url,
        next: api_v1_users_url(page: users.next_page),
        prev: api_v1_users_url(page: users.prev_page)
      }
    }
    
    render json: UserSerializer.new(users, options).serializable_hash
  end
end
```

### Jbuilder
```ruby
# app/views/api/v1/users/show.json.jbuilder
json.user do
  json.extract! @user, :id, :email, :name
  json.created_at @user.created_at.iso8601
  
  json.profile do
    json.extract! @user.profile, :bio, :avatar_url
  end
  
  json.posts @user.posts do |post|
    json.extract! post, :id, :title
    json.url api_v1_post_url(post)
  end
  
  if current_user.admin?
    json.admin_info do
      json.last_login @user.last_login_at
      json.ip_address @user.last_ip
    end
  end
end

# app/views/api/v1/users/index.json.jbuilder
json.users @users do |user|
  json.partial! 'api/v1/users/user', user: user
end

json.meta do
  json.current_page @users.current_page
  json.total_pages @users.total_pages
  json.total_count @users.total_count
end
```

## Authentication

### JWT Authentication
```ruby
# Gemfile
gem 'jwt'

# app/services/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    raise ExceptionHandler::InvalidToken, e.message
  end
end

# app/controllers/concerns/json_web_token_authenticatable.rb
module JsonWebTokenAuthenticatable
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_request
  end
  
  private
  
  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?
    
    begin
      decoded = JsonWebToken.decode(token)
      @current_user = User.find(decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end
```

### OAuth 2.0 с Doorkeeper
```ruby
# Gemfile
gem 'doorkeeper'

# config/initializers/doorkeeper.rb
Doorkeeper.configure do
  orm :active_record
  
  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end
  
  admin_authenticator do
    current_user&.admin? || redirect_to(new_user_session_url)
  end
  
  access_token_expires_in 2.hours
  
  grant_flows %w[authorization_code client_credentials password]
  
  skip_authorization do |resource_owner, client|
    client.trusted?
  end
end

# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  before_action :doorkeeper_authorize!
  
  private
  
  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
```

## Pagination

### Kaminari/Pagy
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  def index
    @users = User.page(params[:page])
                 .per(params[:per_page] || 25)
    
    render json: {
      users: ActiveModelSerializers::SerializableResource.new(@users),
      meta: pagination_meta(@users),
      links: pagination_links(@users)
    }
  end
  
  private
  
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
  
  def pagination_links(collection)
    {
      self: request.url,
      first: api_v1_users_url(page: 1),
      last: api_v1_users_url(page: collection.total_pages),
      next: api_v1_users_url(page: collection.next_page),
      prev: api_v1_users_url(page: collection.prev_page)
    }
  end
end
```

## Error Handling

### Consistent Error Format
```ruby
# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern
  
  class AuthenticationError < StandardError; end
  class MissingToken < StandardError; end
  class InvalidToken < StandardError; end
  
  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      render_error(e.message, :not_found)
    end
    
    rescue_from ActiveRecord::RecordInvalid do |e|
      render_error(e.record.errors.full_messages, :unprocessable_entity)
    end
    
    rescue_from ExceptionHandler::AuthenticationError do |e|
      render_error('Unauthorized', :unauthorized)
    end
    
    rescue_from ExceptionHandler::MissingToken do |e|
      render_error('Missing token', :unprocessable_entity)
    end
    
    rescue_from ExceptionHandler::InvalidToken do |e|
      render_error('Invalid token', :unprocessable_entity)
    end
  end
  
  private
  
  def render_error(messages, status)
    messages = Array(messages)
    
    render json: {
      errors: messages.map { |message| { detail: message } },
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
    }, status: status
  end
end
```

## Documentation

### OpenAPI/Swagger
```ruby
# Gemfile
gem 'rswag'

# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'
  
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'https://api.example.com',
          variables: {
            defaultHost: {
              default: 'api.example.com'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        }
      }
    }
  }
end

# spec/requests/api/v1/users_spec.rb
require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    get 'Lists users' do
      tags 'Users'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer
      parameter name: :per_page, in: :query, type: :integer
      
      response '200', 'success' do
        schema type: :object,
          properties: {
            users: {
              type: :array,
              items: { '$ref' => '#/components/schemas/User' }
            },
            meta: { '$ref' => '#/components/schemas/Pagination' }
          }
        
        run_test!
      end
    end
  end
end
```

## Testing API

### Request specs
```ruby
# spec/requests/api/v1/authentication_spec.rb
require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /api/v1/auth/login' do
    let(:user) { create(:user, password: 'password123') }
    
    context 'with valid credentials' do
      before do
        post '/api/v1/auth/login', params: {
          email: user.email,
          password: 'password123'
        }
      end
      
      it 'returns auth token' do
        expect(json['auth_token']).not_to be_nil
      end
      
      it 'returns success status' do
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'with invalid credentials' do
      before do
        post '/api/v1/auth/login', params: {
          email: user.email,
          password: 'wrong'
        }
      end
      
      it 'returns error message' do
        expect(json['error']).to eq('Invalid credentials')
      end
      
      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

## CORS Configuration

```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_ORIGINS', '*').split(',')
    
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400
  end
end
```

## Рекомендации для Claude Code

1. **Версионируйте API** - всегда с самого начала
2. **Используйте serializers** - для контроля над выводом
3. **Документируйте API** - OpenAPI/Swagger
4. **Consistent responses** - единообразный формат ответов
5. **Proper status codes** - используйте правильные HTTP статусы
6. **Rate limiting** - защита от abuse
7. **Pagination обязательна** - для всех списков
