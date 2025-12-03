# Rails Routing - Маршрутизация

## Основы маршрутизации

### config/routes.rb структура
```ruby
Rails.application.routes.draw do
  # Корневой маршрут
  root "home#index"
  
  # Health check для мониторинга
  get "up" => "rails/health#show", as: :rails_health_check
  
  # PWA маршруты
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  
  # Основные ресурсы
  resources :articles do
    resources :comments, only: [:create, :destroy]
  end
  
  # API namespace
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show]
    end
  end
  
  # Admin namespace с ограничениями
  namespace :admin do
    resources :users
    resources :settings
  end
  
  # Constraints для поддоменов
  constraints subdomain: "api" do
    namespace :api, path: "/" do
      resources :tokens
    end
  end
  
  # Mount engines
  mount Sidekiq::Web => "/sidekiq", constraints: AdminConstraint.new
  mount ActionCable.server => "/cable"
end
```

## RESTful ресурсы

### resources
```ruby
# Полный набор RESTful маршрутов
resources :articles
# GET    /articles          articles#index
# GET    /articles/new      articles#new
# POST   /articles          articles#create
# GET    /articles/:id      articles#show
# GET    /articles/:id/edit articles#edit
# PATCH  /articles/:id      articles#update
# PUT    /articles/:id      articles#update
# DELETE /articles/:id      articles#destroy

# Ограниченный набор
resources :comments, only: [:index, :show, :create]
resources :photos, except: [:destroy]

# Единственный ресурс
resource :profile, only: [:show, :edit, :update]
# GET   /profile      profiles#show
# GET   /profile/edit profiles#edit
# PATCH /profile      profiles#update
```

### Вложенные ресурсы
```ruby
# ✅ ПРАВИЛЬНО - неглубокая вложенность
resources :articles do
  resources :comments, only: [:index, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]

# ✅ Альтернатива - shallow nesting
resources :articles do
  resources :comments, shallow: true
end
# GET    /articles/:article_id/comments     comments#index
# POST   /articles/:article_id/comments     comments#create
# GET    /comments/:id                      comments#show
# PATCH  /comments/:id                      comments#update
# DELETE /comments/:id                      comments#destroy

# ❌ НЕПРАВИЛЬНО - слишком глубокая вложенность
resources :magazines do
  resources :articles do
    resources :comments do
      resources :replies  # Слишком глубоко!
    end
  end
end
```

### Member и Collection маршруты
```ruby
resources :articles do
  # Member маршруты (требуют id)
  member do
    post :publish
    post :archive
    get :preview
  end
  
  # Collection маршруты (без id)
  collection do
    get :published
    get :drafts
    post :bulk_delete
  end
  
  # Короткая запись
  post :favorite, on: :member
  get :search, on: :collection
end

# Результат:
# POST   /articles/:id/publish  articles#publish
# GET    /articles/published    articles#published
```

## Namespaces и Scopes

### namespace
```ruby
# Добавляет префикс к путям, контроллерам и хелперам
namespace :admin do
  resources :users
  resources :products
  root "dashboard#index"
end
# GET /admin/users -> Admin::UsersController#index
# Helper: admin_users_path
```

### scope
```ruby
# Только префикс пути
scope "/admin" do
  resources :users
end
# GET /admin/users -> UsersController#index

# Только модуль контроллера
scope module: "admin" do
  resources :users
end
# GET /users -> Admin::UsersController#index

# Комбинированный scope
scope "/admin", module: "admin", as: "admin" do
  resources :users
end
```

### Разница между namespace и scope
```ruby
# namespace :admin эквивалентно:
scope "/admin", module: "admin", as: "admin" do
  # routes
end
```

## Constraints

### Segment constraints
```ruby
# Ограничение по формату параметра
resources :users, constraints: { id: /\d+/ }

# Или с блоком
constraints(id: /\d+/) do
  resources :posts
  resources :comments
end

# Динамические сегменты
get "posts/:year/:month/:day",
    to: "posts#by_date",
    constraints: {
      year: /\d{4}/,
      month: /\d{1,2}/,
      day: /\d{1,2}/
    }
```

### Request-based constraints
```ruby
# Класс constraint
class AdminConstraint
  def matches?(request)
    request.session[:user_id].present? &&
      User.find(request.session[:user_id]).admin?
  end
end

constraints(AdminConstraint.new) do
  mount Sidekiq::Web => "/sidekiq"
  namespace :admin do
    resources :settings
  end
end

# Lambda constraint
constraints lambda { |req| req.subdomain == "api" } do
  namespace :api, path: "/" do
    resources :endpoints
  end
end

# Встроенные constraints
constraints(subdomain: "api", format: :json) do
  resources :users
end
```

### Route constraints по хосту
```ruby
constraints host: /^admin\./ do
  resources :admin_panels
end

Rails.application.routes.draw do
  constraints subdomain: "app" do
    resources :users
  end
  
  constraints subdomain: ["", "www"] do
    root "marketing#index"
  end
end
```

## Нестандартные маршруты

### get, post, patch, put, delete
```ruby
# Простые маршруты
get "about", to: "pages#about"
get "contact", to: "pages#contact", as: :contact_page

# С параметрами
get "users/:id/posts", to: "users#posts", as: :user_posts

# Все методы для одного пути
match "api/data", to: "api#data", via: [:get, :post]

# Redirect
get "/old-path", to: redirect("/new-path")
get "/stories/:id", to: redirect("/articles/%{id}")
get "/google", to: redirect("https://google.com", status: 302)
```

### Wildcard маршруты
```ruby
# Catch-all маршрут
get "*path", to: "pages#not_found", 
    constraints: lambda { |req| !req.path.starts_with?("/admin") }

# Для статических страниц
get "/pages/*id", to: "pages#show", as: :page
# /pages/about/team -> params[:id] = "about/team"
```

## Direct маршруты и Resolved маршруты

### direct
```ruby
# Кастомные URL helpers
direct :homepage do
  "https://myapp.com"
end

direct :support do
  "https://support.myapp.com/tickets/new"
end

# Использование
link_to "Support", support_url
```

### resolve
```ruby
# Кастомная генерация путей для моделей
resource :profile
resolve("Profile") { [:profile] }

# Теперь можно использовать
link_to "Profile", @profile  # -> /profile
form_with model: @profile     # -> /profile
```

## Маршруты для API

### Версионирование API
```ruby
# URL path версионирование
namespace :api do
  namespace :v1 do
    resources :users
  end
  
  namespace :v2 do
    resources :users do
      resources :posts
    end
  end
end

# Header версионирование
scope module: :v1, constraints: ApiVersion.new("v1") do
  resources :users
end

scope module: :v2, constraints: ApiVersion.new("v2", default: true) do
  resources :users
end

class ApiVersion
  def initialize(version, default = false)
    @version = version
    @default = default
  end
  
  def matches?(request)
    @default || request.headers["Accept"].include?("application/vnd.myapi.#{@version}")
  end
end
```

### JSON API маршруты
```ruby
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    resources :articles, only: [:index, :show, :create, :update, :destroy] do
      resources :relationships, only: [] do
        resources :comments, only: [:index, :create, :destroy]
        resource :author, only: [:show, :update]
      end
    end
  end
end
```

## Concern маршруты

```ruby
# Определение concern
concern :commentable do
  resources :comments, only: [:index, :create]
end

concern :likeable do
  post :like, on: :member
  delete :unlike, on: :member
end

# Использование concerns
resources :articles, concerns: [:commentable, :likeable]
resources :photos, concerns: [:commentable, :likeable]
resources :events, concerns: :commentable

# С параметрами
concern :archivable do |options|
  post :archive, on: :member, **options
  post :unarchive, on: :member, **options
end

resources :posts, concerns: [:archivable]
resources :messages do
  concerns :archivable, defaults: { format: :json }
end
```

## Draw для разделения маршрутов

```ruby
# config/routes.rb
Rails.application.routes.draw do
  draw :api
  draw :admin
  draw :public
end

# config/routes/api.rb
namespace :api do
  namespace :v1 do
    resources :users
    resources :posts
  end
end

# config/routes/admin.rb
namespace :admin do
  resources :dashboard, only: [:index]
  resources :users
end

# config/routes/public.rb
root "home#index"
resources :articles
```

## Отладка маршрутов

### Rails команды
```bash
# Список всех маршрутов
rails routes

# Фильтрация по контроллеру
rails routes -c users
rails routes -c Admin::Users

# Фильтрация по паттерну
rails routes -g POST
rails routes -g admin

# Расширенный формат
rails routes --expanded

# Только неиспользуемые маршруты
rails routes --unused
```

### В коде
```ruby
# В консоли
Rails.application.routes.url_helpers.users_path
app.users_path
app.user_url(1, host: "example.com")

# Проверка маршрута
Rails.application.routes.recognize_path("/users/1", method: :get)
# => {:controller=>"users", :action=>"show", :id=>"1"}
```

## Best Practices

### Порядок маршрутов
```ruby
Rails.application.routes.draw do
  # 1. Корневой маршрут
  root "home#index"
  
  # 2. Concerns
  concern :commentable do
    resources :comments
  end
  
  # 3. Devise или другие gems маршруты
  devise_for :users
  
  # 4. Custom маршруты с constraints
  get "sitemap", to: "sitemap#index", defaults: { format: "xml" }
  
  # 5. Namespaced маршруты
  namespace :api do
    # API routes
  end
  
  namespace :admin do
    # Admin routes
  end
  
  # 6. Основные ресурсы
  resources :articles do
    concerns :commentable
  end
  
  # 7. Catch-all маршруты в самом конце
  match "*path", to: "application#not_found", via: :all
end
```

### Именование маршрутов
```ruby
# ✅ ПРАВИЛЬНО - используйте as для кастомных имен
get "sign_up", to: "users#new", as: :sign_up
get "log_in", to: "sessions#new", as: :log_in
delete "log_out", to: "sessions#destroy", as: :log_out

# ✅ ПРАВИЛЬНО - RESTful naming
resources :articles
resources :user_sessions, only: [:new, :create, :destroy]

# ❌ НЕПРАВИЛЬНО - не RESTful
get "articles/list"
post "articles/create_new"
get "delete_article/:id", to: "articles#delete"
```

## Рекомендации для Claude Code

1. **RESTful first** - всегда предпочитайте RESTful маршруты
2. **Shallow nesting** - избегайте глубокой вложенности
3. **Используйте constraints** - для безопасности и правильной маршрутизации
4. **Namespace для организации** - группируйте связанные маршруты
5. **Тестируйте маршруты** - пишите routing specs
