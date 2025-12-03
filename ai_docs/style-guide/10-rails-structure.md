# Rails 8 Structure - Структура приложения

## Структура директорий

### Стандартная структура Rails 8
```
app/
├── assets/          # Статические ресурсы (устаревает с Propshaft)
├── channels/        # Action Cable каналы
├── controllers/     # Контроллеры
├── helpers/        # View helpers
├── javascript/     # JavaScript с importmaps/esbuild
├── jobs/           # Active Job задачи
├── mailers/        # Action Mailer классы
├── models/         # Active Record модели
├── views/          # Шаблоны представлений
├── components/     # View Components (опционально)
└── services/       # Сервисные объекты (опционально)

config/
├── application.rb  # Основная конфигурация
├── database.yml    # Конфигурация БД
├── routes.rb       # Маршрутизация
├── importmap.rb    # Import maps конфигурация
├── environments/   # Окружения
└── initializers/   # Инициализаторы

db/
├── migrate/        # Миграции
├── schema.rb       # Схема БД
└── seeds.rb        # Начальные данные

lib/
├── tasks/          # Rake задачи
└── assets/         # Кастомные библиотеки

test/ или spec/     # Тесты (Minitest или RSpec)
```

## Организация кода

### Модульная структура (для больших приложений)
```
app/
├── controllers/
│   ├── api/
│   │   ├── v1/
│   │   │   ├── base_controller.rb
│   │   │   └── users_controller.rb
│   │   └── v2/
│   ├── admin/
│   │   ├── base_controller.rb
│   │   └── users_controller.rb
│   └── application_controller.rb
│
├── models/
│   ├── concerns/          # Shared model concerns
│   │   ├── trackable.rb
│   │   └── searchable.rb
│   ├── user.rb
│   └── order.rb
│
├── services/              # Бизнес-логика
│   ├── users/
│   │   ├── registration_service.rb
│   │   └── authentication_service.rb
│   └── payments/
│       └── stripe_service.rb
│
├── queries/               # Сложные запросы
│   └── users/
│       └── active_users_query.rb
│
├── presenters/            # Презентеры
│   └── user_presenter.rb
│
├── validators/            # Кастомные валидаторы
│   └── email_validator.rb
│
├── policies/              # Политики авторизации (Pundit)
│   └── user_policy.rb
│
└── components/            # View Components
    └── users/
        └── avatar_component.rb
```

## Конфигурация

### config/application.rb
```ruby
require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module MyApp
  class Application < Rails::Application
    # Rails 8 defaults
    config.load_defaults 8.0
    
    # Часовой пояс
    config.time_zone = 'Moscow'
    
    # Локализация
    config.i18n.default_locale = :ru
    config.i18n.available_locales = [:ru, :en]
    
    # Автозагрузка путей
    config.autoload_paths << Rails.root.join('app', 'services')
    config.autoload_paths << Rails.root.join('app', 'queries')
    
    # Active Job
    config.active_job.queue_adapter = :solid_queue  # Rails 8 default
    
    # Action Cable
    config.action_cable.mount_path = '/cable'
    
    # Generators
    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.stylesheets false
      g.javascripts false
      g.helper false
    end
  end
end
```

### Окружения

#### config/environments/development.rb
```ruby
Rails.application.configure do
  # Кеширование кода
  config.enable_reloading = true
  config.eager_load = false
  
  # Кеширование
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store
  
  # Active Storage
  config.active_storage.variant_processor = :mini_magick
  
  # Mailer
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  
  # Отладка
  config.consider_all_requests_local = true
  config.server_timing = true
  
  # Propshaft
  config.assets.debug = true
  config.assets.quiet = true
end
```

#### config/environments/production.rb
```ruby
Rails.application.configure do
  # Код
  config.enable_reloading = false
  config.eager_load = true
  
  # Кеширование
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    expires_in: 1.day
  }
  
  # SSL
  config.force_ssl = true
  
  # Логирование
  config.log_level = :info
  config.log_tags = [:request_id]
  
  # Active Storage
  config.active_storage.variant_processor = :vips
  
  # Action Cable
  config.action_cable.allowed_request_origins = [
    'https://example.com',
    /https:\/\/.*\.example\.com/
  ]
end
```

## База данных

### config/database.yml
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: myapp_development
  username: myapp
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: localhost

test:
  <<: *default
  database: myapp_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Множественные базы данных
```yaml
production:
  primary:
    <<: *default
    url: <%= ENV['PRIMARY_DATABASE_URL'] %>
  
  animals:
    <<: *default
    url: <%= ENV['ANIMALS_DATABASE_URL'] %>
    migrations_paths: db/animals_migrate
```

## Инициализаторы

### config/initializers/inflections.rb
```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural /^(ox)$/i, '\1en'
  inflect.singular /^(ox)en/i, '\1'
  inflect.irregular 'person', 'people'
  inflect.uncountable %w( fish sheep )
  
  # Для русских слов
  inflect.acronym 'API'
  inflect.acronym 'HTML'
  inflect.acronym 'JSON'
end
```

### config/initializers/filter_parameter_logging.rb
```ruby
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :token,
  :secret,
  :api_key,
  :credit_card_number,
  :cvv
]
```

## Credentials

### Использование credentials
```ruby
# Редактирование
# rails credentials:edit --environment production

# config/credentials/production.yml.enc
aws:
  access_key_id: xxx
  secret_access_key: xxx

stripe:
  publishable_key: xxx
  secret_key: xxx

# Доступ в коде
Rails.application.credentials.aws[:access_key_id]
Rails.application.credentials.dig(:stripe, :secret_key)
```

## Import Maps (Rails 8 default)

### config/importmap.rb
```ruby
# Pin npm packages
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Pin local modules
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/helpers", under: "helpers"

# External packages
pin "axios", to: "https://cdn.jsdelivr.net/npm/axios@1.5.0/+esm"
pin "lodash", to: "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm"
```

## Solid Queue (Rails 8 default)

### config/solid_queue.yml
```yaml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  
  workers:
    - queues: "*"
      threads: 5
      processes: 2
      polling_interval: 0.1

development:
  dispatchers:
    - polling_interval: 1
  
  workers:
    - queues: "*"
      threads: 3
      polling_interval: 0.1
```

## Propshaft (Rails 8 asset pipeline)

### config/initializers/propshaft.rb
```ruby
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
Rails.application.config.assets.paths << Rails.root.join("vendor/javascript")

# Сжатие в production
Rails.application.config.assets.css_compressor = :sass
Rails.application.config.assets.js_compressor = :terser
```

## Локализация

### config/locales/ru.yml
```yaml
ru:
  activerecord:
    models:
      user: Пользователь
      order: Заказ
    attributes:
      user:
        email: Email
        name: Имя
        password: Пароль
    errors:
      messages:
        blank: не может быть пустым
        invalid: имеет неверный формат
  
  date:
    formats:
      default: "%d.%m.%Y"
      short: "%d %b"
      long: "%d %B %Y"
  
  time:
    formats:
      default: "%d.%m.%Y %H:%M"
      short: "%d %b %H:%M"
```

## Заметки по Rails 8

### Новые возможности Rails 8
1. **Solid Queue** - встроенная очередь задач на базе БД
2. **Solid Cache** - кеширование в БД
3. **Solid Cable** - WebSocket на базе БД
4. **Propshaft** - упрощенный asset pipeline
5. **Kamal 2** - деплой контейнеров
6. **Built-in Rate Limiting** - ограничение запросов
7. **Built-in Authentication** - базовая аутентификация

### Изменения в defaults
```ruby
# Rails 8 новые defaults
config.load_defaults 8.0

# Включает:
# - Solid Queue как default adapter
# - Propshaft вместо Sprockets
# - Import maps по умолчанию
# - Ruby 3.3+ требования
# - Новые Active Record оптимизации
```

## Рекомендации для Claude Code

1. **Следуйте конвенциям Rails** - не изобретайте велосипед
2. **Используйте генераторы** - `rails generate` для консистентности
3. **Организуйте по функциям** - группируйте связанный код
4. **Изолируйте бизнес-логику** - используйте сервисные объекты
5. **Тестируйте конфигурацию** - проверяйте все окружения
