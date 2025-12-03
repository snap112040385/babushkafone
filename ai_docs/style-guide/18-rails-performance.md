# Rails Performance - Производительность (продолжение)

## Background Jobs (продолжение)

### Оптимизация задач
```ruby
class ProcessDataJob < ApplicationJob
  queue_as :default
  
  # Batching
  def perform(batch_size: 1000)
    User.where(processed: false)
        .find_in_batches(batch_size: batch_size) do |users|
      process_batch(users)
    end
  end
  
  private
  
  def process_batch(users)
    # Bulk update вместо индивидуальных
    user_ids = users.map(&:id)
    User.where(id: user_ids).update_all(
      processed: true,
      processed_at: Time.current
    )
  end
end

# Использование Solid Queue (Rails 8)
class ImportantJob < ApplicationJob
  queue_as :critical
  
  # Retry стратегия
  retry_on NetworkError, wait: :exponentially_longer, attempts: 5
  
  # Отбрасывание при определенных ошибках
  discard_on ActiveRecord::RecordNotFound
  
  # Timeout
  def perform(data)
    Timeout.timeout(30) do
      process_data(data)
    end
  end
end
```

### Bulk операции
```ruby
# ❌ ПЛОХО - N запросов
users.each do |user|
  user.update(status: 'active')
end

# ✅ ХОРОШО - 1 запрос
User.where(id: user_ids).update_all(status: 'active')

# ✅ Insert many
users_data = [
  { name: 'John', email: 'john@example.com' },
  { name: 'Jane', email: 'jane@example.com' }
]
User.insert_all(users_data)

# ✅ Upsert (insert or update)
User.upsert_all(
  users_data,
  unique_by: :email,
  update_only: [:name]
)
```

## Asset Pipeline оптимизация

### Propshaft (Rails 8)
```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.css_compressor = :sass
config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

# CDN настройка
config.asset_host = ENV['CDN_HOST']

# Compression
config.middleware.use Rack::Deflater
```

### Import Maps оптимизация
```ruby
# config/importmap.rb
# Пин только необходимые модули
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true

# Lazy loading для больших библиотек
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4/+esm"

# Preload критичных ресурсов
pin "critical_module", preload: true
```

## Database Connection Pool

### Настройка пула
```yaml
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # Дополнительные оптимизации для PostgreSQL
  variables:
    statement_timeout: '30s'
    lock_timeout: '10s'
    idle_in_transaction_session_timeout: '60s'
```

### Connection pool в коде
```ruby
# config/puma.rb
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
```

## Память и GC

### Оптимизация памяти
```ruby
# config/application.rb
# Jemalloc для лучшего управления памятью
ENV['LD_PRELOAD'] = '/usr/lib/x86_64-linux-gnu/libjemalloc.so.2'

# Настройки GC
if defined?(GC::Profiler)
  GC::Profiler.enable
end

# config/puma.rb
before_fork do
  GC.compact if GC.respond_to?(:compact)
end
```

### Избежание утечек памяти
```ruby
# ❌ ПЛОХО - держит все объекты в памяти
def process_all_users
  users = User.all.to_a
  users.each { |user| process(user) }
end

# ✅ ХОРОШО - обрабатывает батчами
def process_all_users
  User.find_each(batch_size: 100) do |user|
    process(user)
  end
end

# ✅ Очистка после больших операций
def generate_report
  data = fetch_large_dataset
  result = process_data(data)
  
  # Явная очистка
  data = nil
  GC.start
  
  result
end
```

## Lazy Loading и Eager Loading

### ViewComponent с lazy loading
```ruby
# app/components/comments_component.rb
class CommentsComponent < ViewComponent::Base
  include Turbo::FramesHelper
  
  def initialize(post:, lazy: false)
    @post = post
    @lazy = lazy
  end
  
  def render?
    @post.comments_count > 0
  end
  
  def call
    if @lazy
      turbo_frame_tag "comments_#{@post.id}", 
                      src: post_comments_path(@post),
                      loading: :lazy do
        content_tag :div, "Loading comments...", 
                    class: "text-muted"
      end
    else
      render_comments
    end
  end
end
```

## Monitoring и Profiling

### APM интеграция
```ruby
# Gemfile
gem 'newrelic_rpm'
gem 'skylight'
gem 'scout_apm'

# config/newrelic.yml
production:
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: MyApp Production
  log_level: info
  
  # Настройки производительности
  browser_monitoring:
    auto_instrument: true
  
  slow_sql:
    enabled: true
    threshold: 0.5
```

### Встроенный profiling
```ruby
# Development профилирование
class PerformanceMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    return @app.call(env) unless Rails.env.development?
    
    result = nil
    sql_queries = []
    
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql_queries << { sql: event.payload[:sql], duration: event.duration }
    end
    
    time = Benchmark.realtime { result = @app.call(env) }
    
    ActiveSupport::Notifications.unsubscribe(subscriber)
    
    Rails.logger.info "=" * 50
    Rails.logger.info "Request took: #{(time * 1000).round(2)}ms"
    Rails.logger.info "SQL queries: #{sql_queries.size}"
    Rails.logger.info "SQL time: #{sql_queries.sum { |q| q[:duration] }.round(2)}ms"
    Rails.logger.info "=" * 50
    
    result
  end
end

# config/environments/development.rb
config.middleware.use PerformanceMiddleware
```

## Query оптимизация паттерны

### Query Objects
```ruby
# app/queries/active_users_query.rb
class ActiveUsersQuery
  def initialize(relation = User.all)
    @relation = relation
  end
  
  def call
    @relation
      .where(active: true)
      .where('last_login_at > ?', 30.days.ago)
      .includes(:profile)
      .select(:id, :email, :name, :last_login_at)
  end
  
  def with_posts
    call.includes(:posts)
  end
  
  def paginated(page: 1, per: 25)
    call.page(page).per(per)
  end
end

# Использование
active_users = ActiveUsersQuery.new.paginated(page: params[:page])
```

### Service Objects для сложных операций
```ruby
# app/services/report_generator.rb
class ReportGenerator
  def initialize(date_range)
    @date_range = date_range
  end
  
  def call
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      {
        users: fetch_users_data,
        orders: fetch_orders_data,
        revenue: calculate_revenue
      }
    end
  end
  
  private
  
  def fetch_users_data
    User.where(created_at: @date_range)
        .group_by_day(:created_at)
        .count
  end
  
  def fetch_orders_data
    # Использование raw SQL для сложных запросов
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as count,
        SUM(total) as revenue
      FROM orders
      WHERE created_at BETWEEN '#{@date_range.begin}' AND '#{@date_range.end}'
      GROUP BY DATE(created_at)
    SQL
  end
  
  def cache_key
    "report/#{@date_range.begin}/#{@date_range.end}"
  end
end
```

## Turbo оптимизация

### Turbo Frames для частичных обновлений
```erb
<!-- Ленивая загрузка -->
<turbo-frame id="expensive_widget" 
             src="<%= expensive_widget_path %>" 
             loading="lazy">
  <div class="skeleton-loader">Loading...</div>
</turbo-frame>

<!-- Обновление только изменившихся частей -->
<turbo-frame id="notifications_count">
  <%= current_user.notifications.unread.count %>
</turbo-frame>
```

### Turbo Streams для real-time
```ruby
class Comment < ApplicationRecord
  after_create_commit do
    broadcast_append_to post,
                       target: "comments",
                       partial: "comments/comment",
                       locals: { comment: self }
  end
  
  after_destroy_commit do
    broadcast_remove_to post
  end
end
```

## Конфигурация для производительности

### config/environments/production.rb
```ruby
Rails.application.configure do
  # Кеширование классов
  config.enable_reloading = false
  config.eager_load = true
  
  # Кеширование
  config.action_controller.perform_caching = true
  config.cache_store = :mem_cache_store
  
  # Статические файлы
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.year.to_i}"
  }
  
  # Сжатие
  config.middleware.use Rack::Deflater
  
  # Отключить ненужное в production
  config.action_view.raise_on_missing_translations = false
  config.active_record.dump_schema_after_migration = false
  
  # Логирование
  config.log_level = :info
  config.log_tags = [:request_id]
  
  # Precompile assets
  config.assets.compile = false
  config.assets.digest = true
end
```

## Рекомендации для Claude Code

1. **Измеряйте перед оптимизацией** - используйте профилирование
2. **N+1 queries** - всегда используйте includes/joins
3. **Кешируйте агрессивно** - но с правильной инвалидацией
4. **Database индексы** - критичны для производительности
5. **Background jobs** - для тяжелых операций
6. **Pagination** - всегда для списков
7. **CDN для assets** - уменьшает нагрузку на сервер
