# Ruby Classes & Modules - Классы, модули и ООП

## Структура класса

### Стандартный порядок элементов
```ruby
class Person
  # 1. extend/include/prepend
  extend SomeModule
  include AnotherModule
  prepend YetAnotherModule
  
  # 2. Внутренние классы
  class CustomError < StandardError; end
  
  # 3. Константы
  MAX_NAME_LENGTH = 100
  VALID_STATUSES = %i[active inactive pending].freeze
  
  # 4. Макросы атрибутов
  attr_reader :name, :email
  attr_accessor :status
  
  # 5. Другие макросы
  validates :name, presence: true
  has_many :orders
  
  # 6. Публичные методы класса
  def self.find_by_email(email)
    # implementation
  end
  
  # 7. Инициализация
  def initialize(name, email)
    @name = name
    @email = email
    @status = :pending
  end
  
  # 8. Публичные методы экземпляра
  def activate!
    @status = :active
  end
  
  # 9. Protected методы
  protected
  
  def internal_method
    # implementation
  end
  
  # 10. Private методы
  private
  
  def validate_email
    # implementation
  end
end
```

## Определение классов

### Многострочные классы
```ruby
# ✅ ПРАВИЛЬНО - стандартное определение
class FooError < StandardError
end

# ❌ НЕПРАВИЛЬНО - однострочное определение
class FooError < StandardError; end

# ❌ НЕПРАВИЛЬНО - Class.new
FooError = Class.new(StandardError)
```

### Вложенные классы
```ruby
# ✅ ПРАВИЛЬНО - каждый класс в отдельном файле
# foo.rb
class Foo
  # 30 methods inside
end

# foo/bar.rb
class Foo
  class Bar
    # implementation
  end
end

# ❌ НЕПРАВИЛЬНО - все в одном файле
class Foo
  class Bar
    # 30 methods
  end
  
  class Baz
    # 20 methods
  end
  
  # 30 methods
end
```

### Пространства имен
```ruby
# ✅ ПРАВИЛЬНО - явная вложенность
module Utilities
  class Queue
    def initialize
      @items = []
    end
  end
end

module Utilities
  class Stack
    def initialize
      @queue = Queue.new  # Найдет Utilities::Queue
    end
  end
end

# ❌ НЕПРАВИЛЬНО - scope resolution может привести к ошибкам
class Utilities::Stack
  def initialize
    @queue = Queue.new  # Будет искать ::Queue, не Utilities::Queue
  end
end
```

## Модули

### module_function vs extend self
```ruby
# ✅ ПРАВИЛЬНО - используйте module_function
module Utilities
  module_function
  
  def parse_something(string)
    # implementation
  end
  
  def format_date(date)
    # implementation
  end
end

# Использование
Utilities.parse_something("text")
include Utilities
parse_something("text")

# ❌ НЕПРАВИЛЬНО
module Utilities
  extend self
  
  def parse_something(string)
    # implementation
  end
end
```

### Миксины
```ruby
# ✅ ПРАВИЛЬНО - каждый миксин на отдельной строке
class Person
  include Validatable
  include Timestampable
  extend Searchable
end

# ❌ НЕПРАВИЛЬНО
class Person
  include Validatable, Timestampable
end
```

### Модули как пространства имен
```ruby
# ✅ ПРАВИЛЬНО - модуль для группировки классов
module API
  module V1
    class UsersController < BaseController
      # implementation
    end
  end
end
```

## Наследование и композиция

### Предпочитайте композицию
```ruby
# ✅ ПРАВИЛЬНО - композиция через duck typing
class Duck
  def speak
    puts 'Quack! Quack'
  end
end

class Dog
  def speak
    puts 'Woof! Woof!'
  end
end

# ❌ НЕПРАВИЛЬНО - глубокая иерархия наследования
class Animal
  def speak
    raise NotImplementedError
  end
end

class Duck < Animal
  def speak
    puts 'Quack! Quack'
  end
end
```

## Атрибуты

### Использование attr_* методов
```ruby
# ✅ ПРАВИЛЬНО
class Person
  attr_reader :first_name, :last_name
  attr_accessor :age
  attr_writer :password
  
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end
end

# ❌ НЕПРАВИЛЬНО - ручное определение
class Person
  def first_name
    @first_name
  end
  
  def first_name=(value)
    @first_name = value
  end
end
```

### Кастомные аксессоры
```ruby
# ✅ ПРАВИЛЬНО - Ruby style
class Person
  def full_name
    "#{@first_name} #{@last_name}"
  end
  
  def full_name=(value)
    @first_name, @last_name = value.split(' ')
  end
end

# ❌ НЕПРАВИЛЬНО - Java style
class Person
  def get_full_name
    "#{@first_name} #{@last_name}"
  end
  
  def set_full_name(value)
    @first_name, @last_name = value.split(' ')
  end
end
```

## Struct и Data

### Использование Struct
```ruby
# ✅ ПРАВИЛЬНО - Struct для простых данных
Person = Struct.new(:first_name, :last_name, :age) do
  def full_name
    "#{first_name} #{last_name}"
  end
end

# ❌ НЕПРАВИЛЬНО - наследование от Struct.new
class Person < Struct.new(:first_name, :last_name)
end
```

### Ruby 3.2+ Data
```ruby
# ✅ ПРАВИЛЬНО - Data для иммутабельных объектов
Person = Data.define(:first_name, :last_name) do
  def full_name
    "#{first_name} #{last_name}"
  end
end

# ❌ НЕПРАВИЛЬНО - наследование от Data.define
class Person < Data.define(:first_name, :last_name)
end
```

## Переменные класса и экземпляра

### Избегайте переменных класса
```ruby
# ❌ НЕПРАВИЛЬНО - проблемы с наследованием
class Parent
  @@count = 0
  
  def self.increment
    @@count += 1
  end
end

class Child < Parent
  @@count = 100  # Перезаписывает Parent::@@count!
end

# ✅ ПРАВИЛЬНО - переменные экземпляра класса
class Parent
  @count = 0
  
  class << self
    attr_accessor :count
    
    def increment
      self.count += 1
    end
  end
end

class Child < Parent
  @count = 100  # Независимая переменная
end
```

## Инициализация

### Конструкторы
```ruby
# ✅ ПРАВИЛЬНО - простое присваивание
class User
  def initialize(name, email = nil)
    @name = name
    @email = email
    @created_at = Time.current
  end
end

# ❌ НЕПРАВИЛЬНО - избыточное ||=
class User
  def initialize(name = nil)
    @name ||= name  # @name и так nil изначально
  end
end
```

### Фабричные методы
```ruby
# ✅ ПРАВИЛЬНО - дополнительные способы создания
class User
  def self.from_oauth(auth_hash)
    new(
      name: auth_hash[:info][:name],
      email: auth_hash[:info][:email]
    )
  end
  
  def self.guest
    new(name: 'Guest', email: 'guest@example.com')
  end
  
  def initialize(name:, email:)
    @name = name
    @email = email
  end
end
```

## Методы экземпляра

### to_s
```ruby
# ✅ ПРАВИЛЬНО - всегда определяйте to_s для domain объектов
class Person
  attr_reader :first_name, :last_name
  
  def to_s
    "#{first_name} #{last_name}"
  end
end
```

### Методы сравнения
```ruby
# ✅ ПРАВИЛЬНО
class Person
  include Comparable
  
  attr_reader :age
  
  def <=>(other)
    age <=> other.age
  end
  
  def eql?(other)
    self.class == other.class && age == other.age
  end
  
  def hash
    [self.class, age].hash
  end
end
```

## self использование

### Когда self необходим
```ruby
class User
  attr_accessor :status
  
  def activate!
    self.status = :active  # Необходим для вызова сеттера
    save  # self не нужен
  end
  
  def self.find_all  # Необходим для метода класса
    # implementation
  end
end
```

### Избегайте избыточного self
```ruby
# ✅ ПРАВИЛЬНО
class User
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def admin?
    role == 'admin'
  end
end

# ❌ НЕПРАВИЛЬНО
class User
  def full_name
    "#{self.first_name} #{self.last_name}"
  end
  
  def admin?
    self.role == 'admin'
  end
end
```

## Константы

### Определение
```ruby
# ✅ ПРАВИЛЬНО - определяйте на уровне класса
class Config
  API_VERSION = '1.0'
  TIMEOUT = 30
  VALID_TYPES = %i[json xml].freeze
end

# ❌ НЕПРАВИЛЬНО - определение в блоке
task :lint do
  FILES_TO_LINT = Dir['lib/*.rb']  # Создает глобальную константу!
end
```

## Принципы проектирования

### SOLID принципы
```ruby
# Single Responsibility
class UserMailer
  def send_welcome_email(user)
    # только отправка email
  end
end

# Open/Closed
class PaymentProcessor
  def process(payment_method)
    payment_method.charge  # открыт для расширения через новые payment methods
  end
end

# Liskov Substitution
# Dependency Inversion
class OrderService
  def initialize(payment_gateway)
    @payment_gateway = payment_gateway  # зависит от абстракции
  end
end
```

## Рекомендации для Claude Code

1. **Маленькие классы** - один класс = одна ответственность
2. **Композиция над наследованием** - используйте миксины и duck typing
3. **Иммутабельность** - предпочитайте иммутабельные объекты где возможно
4. **Документирование** - документируйте публичный API
5. **Тестирование** - проектируйте классы удобными для тестирования
