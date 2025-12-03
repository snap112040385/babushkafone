# Rails Models - Модели и Active Record

## Структура модели

### Порядок элементов в модели
```ruby
class User < ApplicationRecord
  # 1. Includes/Extends
  include Trackable
  extend FriendlyId
  
  # 2. Константы
  ROLES = %w[admin moderator user].freeze
  MAX_NAME_LENGTH = 100
  
  # 3. Атрибуты и сериализация
  attribute :preferences, :json, default: {}
  store_accessor :preferences, :theme, :language
  
  # 4. Связи (associations)
  belongs_to :organization, optional: true
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_one :profile, dependent: :destroy
  has_one_attached :avatar
  has_many_attached :documents
  
  # 5. Делегирование
  delegate :name, to: :profile, prefix: true, allow_nil: true
  
  # 6. Валидации
  validates :email, presence: true, uniqueness: true
  validates :name, length: { maximum: MAX_NAME_LENGTH }
  
  # 7. Callbacks
  before_validation :normalize_email
  after_create :send_welcome_email
  
  # 8. Scopes
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: 'admin') }
  default_scope { order(created_at: :desc) }
  
  # 9. Методы класса
  def self.find_by_email(email)
    find_by(email: email.downcase)
  end
  
  # 10. Методы экземпляра
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  private
  
  # 11. Приватные методы
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
```

## Именование

### Модели
```ruby
# ✅ ПРАВИЛЬНО - единственное число
class User < ApplicationRecord
end

class OrderItem < ApplicationRecord
end

# ❌ НЕПРАВИЛЬНО
class Users < ApplicationRecord
end
```

### Таблицы
```ruby
# Миграция создает таблицу во множественном числе
create_table :users do |t|
  t.string :email
  t.timestamps
end

# Модель в единственном числе
class User < ApplicationRecord
end
```

## Связи (Associations)

### belongs_to
```ruby
class Article < ApplicationRecord
  # Обязательная связь (default в Rails 5+)
  belongs_to :user
  
  # Опциональная связь
  belongs_to :category, optional: true
  
  # С другим именем
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  
  # С условием
  belongs_to :published_by, -> { where(role: 'editor') },
             class_name: 'User',
             optional: true
  
  # Counter cache
  belongs_to :user, counter_cache: true
  # или с кастомным именем
  belongs_to :user, counter_cache: :articles_count
end
```

### has_many
```ruby
class User < ApplicationRecord
  # Базовая связь
  has_many :articles
  
  # С условиями
  has_many :published_articles, -> { where(published: true) },
           class_name: 'Article'
  
  # С сортировкой
  has_many :recent_articles, -> { order(created_at: :desc).limit(5) },
           class_name: 'Article'
  
  # Dependent стратегии
  has_many :posts, dependent: :destroy        # удалит записи
  has_many :comments, dependent: :delete_all  # удалит без callbacks
  has_many :likes, dependent: :nullify        # обнулит foreign key
  has_many :views, dependent: :restrict_with_exception
  
  # Through association
  has_many :comments, through: :posts
  has_many :commenters, through: :comments, source: :user
  
  # Полиморфная
  has_many :images, as: :imageable
end
```

### has_one
```ruby
class User < ApplicationRecord
  # Базовая связь
  has_one :profile
  
  # С условием
  has_one :active_subscription, -> { where(active: true) },
          class_name: 'Subscription'
  
  # Through
  has_one :current_plan, through: :active_subscription, source: :plan
end
```

### has_and_belongs_to_many (избегайте)
```ruby
# ❌ НЕПРАВИЛЬНО - используйте has_many through
class User < ApplicationRecord
  has_and_belongs_to_many :groups
end

# ✅ ПРАВИЛЬНО - больше контроля
class User < ApplicationRecord
  has_many :memberships
  has_many :groups, through: :memberships
end

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group
  
  # Можно добавить дополнительные поля
  # role, joined_at, etc.
end
```

## Валидации

### Встроенные валидации
```ruby
class User < ApplicationRecord
  # Присутствие
  validates :name, presence: true
  
  # Уникальность
  validates :email, uniqueness: true
  validates :username, uniqueness: { case_sensitive: false }
  validates :email, uniqueness: { scope: :organization_id }
  
  # Длина
  validates :password, length: { minimum: 8 }
  validates :bio, length: { maximum: 500 }
  validates :name, length: { in: 2..100 }
  
  # Формат
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{10}\z/ }
  
  # Числовые
  validates :age, numericality: { greater_than: 0 }
  validates :rating, numericality: { in: 1..5 }
  
  # Включение
  validates :status, inclusion: { in: %w[active pending archived] }
  validates :role, exclusion: { in: %w[superadmin] }
  
  # Подтверждение
  validates :email, confirmation: true  # требует email_confirmation
  
  # Условные валидации
  validates :card_number, presence: true, if: :paid_with_card?
  validates :password, confirmation: true, unless: :guest?
  
  # С кастомным сообщением
  validates :name, presence: { message: 'не может быть пустым' }
end
```

### Кастомные валидации
```ruby
class User < ApplicationRecord
  # Метод валидации
  validate :email_not_from_blocked_domain
  
  # Кастомный валидатор
  validates_with EmailValidator
  validates :email, email: true  # используя EmailValidator
  
  private
  
  def email_not_from_blocked_domain
    if email.present? && BLOCKED_DOMAINS.any? { |d| email.ends_with?(d) }
      errors.add(:email, 'использует заблокированный домен')
    end
  end
end

# app/validators/email_validator.rb
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ URI::MailTo::EMAIL_REGEXP
      record.errors.add(attribute, options[:message] || 'неверный формат')
    end
  end
end
```

## Callbacks

### Порядок выполнения
```ruby
class User < ApplicationRecord
  # 1. before_validation
  before_validation :normalize_data
  
  # 2. after_validation
  after_validation :set_defaults
  
  # 3. before_save
  before_save :encrypt_password
  
  # 4. around_save
  around_save :log_save
  
  # 5. before_create / before_update
  before_create :set_activation_token
  before_update :check_email_change
  
  # 6. after_create / after_update
  after_create :send_welcome_email
  after_update :notify_profile_update
  
  # 7. after_save
  after_save :clear_cache
  
  # 8. after_commit / after_rollback
  after_commit :index_in_elasticsearch
  after_rollback :log_failure
end
```

### Условные callbacks
```ruby
class Order < ApplicationRecord
  # С условием
  before_save :calculate_total, if: :items_changed?
  after_create :send_notification, unless: :skip_notification?
  
  # С lambda
  before_validation :set_defaults, if: -> { new_record? }
  
  # Только для определенных атрибутов
  before_save :geocode_address, if: :will_save_change_to_address?
end
```

## Scopes

### Определение и использование
```ruby
class Article < ApplicationRecord
  # Простые scopes
  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # С параметрами
  scope :by_author, ->(author) { where(author: author) }
  scope :created_after, ->(date) { where('created_at > ?', date) }
  
  # Композиция
  scope :featured_recent, -> { featured.recent.limit(5) }
  
  # Методы класса как scopes (для сложной логики)
  def self.with_comments_count
    left_joins(:comments)
      .group(:id)
      .select('articles.*, COUNT(comments.id) as comments_count')
  end
end

# Использование
Article.published.recent
Article.featured.by_author(current_user)
Article.created_after(1.week.ago)
```

### default_scope (используйте осторожно)
```ruby
class Article < ApplicationRecord
  # ⚠️ Будет применяться ВСЕГДА
  default_scope { where(deleted_at: nil) }
  
  # Отключение default_scope
  Article.unscoped.all
end
```

## Enums

```ruby
class Order < ApplicationRecord
  # Rails 7+ синтаксис
  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4
  }, default: :pending
  
  # Со префиксом/суффиксом
  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    refunded: 2
  }, prefix: true  # payment_status_unpaid?, payment_status_paid?
  
  # Использование
  # order.pending? # => true/false
  # order.shipped! # изменить статус
  # Order.pending  # scope
end
```

## Concerns

```ruby
# app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern
  
  included do
    has_many :activities, as: :trackable, dependent: :destroy
    
    after_create :log_creation
    after_update :log_update
  end
  
  class_methods do
    def recently_updated(since = 1.week.ago)
      where('updated_at > ?', since)
    end
  end
  
  def track_activity(action)
    activities.create!(action: action, user: Current.user)
  end
  
  private
  
  def log_creation
    track_activity('created')
  end
  
  def log_update
    track_activity('updated')
  end
end

# Использование
class Article < ApplicationRecord
  include Trackable
end
```

## Query Interface

### Эффективные запросы
```ruby
# ✅ ПРАВИЛЬНО - использует индексы
User.where(email: 'user@example.com')
User.where(created_at: 1.week.ago..Time.current)

# Включение связанных данных (N+1 prevention)
posts = Post.includes(:user, :comments).limit(10)

# Joins для фильтрации
Post.joins(:comments).where(comments: { approved: true })

# Подзапросы
User.where(id: Post.select(:user_id))

# Использование SQL
User.where('age > ? AND created_at > ?', 18, 1.year.ago)
```

### Избегайте N+1
```ruby
# ❌ ПЛОХО - N+1 запросов
posts = Post.all
posts.each { |post| puts post.user.name }

# ✅ ХОРОШО - 2 запроса
posts = Post.includes(:user)
posts.each { |post| puts post.user.name }

# ✅ Для условной загрузки
posts = Post.includes(:comments).where(comments: { approved: true })
```

## Рекомендации для Claude Code

1. **Тонкие модели** - выносите сложную логику в сервисы
2. **Используйте валидации БД** - добавляйте constraints в миграциях
3. **Индексы** - добавляйте для foreign keys и часто запрашиваемых полей
4. **Избегайте callbacks** - для сложной логики используйте сервисы
5. **Тестируйте ассоциации** - проверяйте dependent стратегии
