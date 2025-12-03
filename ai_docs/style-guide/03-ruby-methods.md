# Ruby Methods - Методы и их определения

## Определение методов

### Скобки в определении
```ruby
# ✅ ПРАВИЛЬНО - со скобками при наличии параметров
def some_method(arg1, arg2)
  # body
end

# ✅ ПРАВИЛЬНО - без скобок если нет параметров
def some_method
  # body
end

# ❌ НЕПРАВИЛЬНО
def some_method()
  # body
end

def some_method_with_params param1, param2
  # body
end
```

### Длина методов
```ruby
# ✅ ПРАВИЛЬНО - короткие методы (до 10 строк)
def calculate_total
  subtotal = items.sum(&:price)
  tax = subtotal * tax_rate
  shipping = calculate_shipping
  subtotal + tax + shipping
end

# ❌ НЕПРАВИЛЬНО - слишком длинный метод
def process_order
  # 50+ строк кода
  # Разбейте на несколько методов
end
```

### Однострочные методы (избегайте)
```ruby
# ❌ НЕПРАВИЛЬНО - классический однострочный метод
def too_much; something; something_else; end

# ✅ ПРАВИЛЬНО - многострочный метод
def some_method
  something
  something_else
end

# ✅ OK - пустые методы
def no_op; end

# ✅ OK - Ruby 3+ endless методы для простых случаев
def square(x) = x * x
def the_answer = 42
```

## Вызов методов

### Скобки при вызове
```ruby
# ✅ ПРАВИЛЬНО - используйте скобки для методов с аргументами
x = Math.sin(y)
array.delete(item)
temperance = Person.new('Temperance', 30)

# ✅ ПРАВИЛЬНО - опускайте скобки для DSL методов
class Person < ApplicationRecord
  validates :name, presence: true
  has_many :orders
  before_save :normalize_email
end

# ✅ ПРАВИЛЬНО - опускайте скобки для методов без аргументов
2.even?
fork
'test'.upcase
```

### Пробелы при вызове
```ruby
# ✅ ПРАВИЛЬНО
puts(x + y)
collection[index]

# ❌ НЕПРАВИЛЬНО
puts (x + y)  # пробел между именем метода и скобкой
collection [index]  # пробел перед скобками
```

## Параметры методов

### Обязательные и опциональные параметры
```ruby
# ✅ ПРАВИЛЬНО - опциональные в конце
def some_method(required1, required2, optional1 = 1, optional2 = 2)
  # body
end

# ❌ НЕПРАВИЛЬНО - опциональные в начале
def some_method(a = 1, b = 2, c, d)
  # body
end
```

### Именованные параметры (keyword arguments)
```ruby
# ✅ ПРАВИЛЬНО - используйте для boolean и опциональных параметров
def create_user(name:, email:, admin: false, active: true)
  # body
end

# Вызов
create_user(name: 'John', email: 'john@example.com')
create_user(name: 'Jane', email: 'jane@example.com', admin: true)

# ✅ ПРАВИЛЬНО - обязательные keyword аргументы первыми
def some_method(required:, another_required:, optional: false)
  # body
end
```

### Hash как параметры (Ruby 2.7+)
```ruby
# ✅ ПРАВИЛЬНО - опускайте фигурные скобки для последнего хеша
user.update(name: 'John', age: 30, permissions: { read: true })

# ❌ НЕПРАВИЛЬНО
user.update({ name: 'John', age: 30 })
```

### Максимальное количество параметров
```ruby
# ✅ ПРАВИЛЬНО - до 3-4 параметров
def send_email(to, subject, body)
  # body
end

# ✅ ПРАВИЛЬНО - используйте keyword arguments для большего числа
def send_email(to:, subject:, body:, cc: nil, bcc: nil, attachments: [])
  # body
end

# ❌ НЕПРАВИЛЬНО - слишком много позиционных параметров
def send_email(to, from, subject, body, cc, bcc, attachments, priority)
  # body
end
```

## Переадресация аргументов

### Ruby 2.7+ forwarding
```ruby
# ✅ ПРАВИЛЬНО - используйте ...
def some_method(...)
  other_method(...)
end

# ❌ НЕПРАВИЛЬНО - старый стиль
def some_method(*args, **kwargs, &block)
  other_method(*args, **kwargs, &block)
end
```

### Ruby 3.1+ анонимная переадресация блоков
```ruby
# ✅ ПРАВИЛЬНО
def some_method(&)
  other_method(&)
end

# ❌ НЕПРАВИЛЬНО
def some_method(&block)
  other_method(&block)
end
```

## Возвращаемые значения

### Неявный return
```ruby
# ✅ ПРАВИЛЬНО - Ruby автоматически возвращает последнее выражение
def calculate_total
  subtotal = 100
  tax = 10
  subtotal + tax
end

# ❌ НЕПРАВИЛЬНО - избыточный return
def calculate_total
  subtotal = 100
  tax = 10
  return subtotal + tax
end

# ✅ OK - return для раннего выхода
def process(value)
  return nil if value.nil?
  return 0 if value.zero?
  
  value * 2
end
```

## Методы класса

### Определение
```ruby
# ✅ ПРАВИЛЬНО - используйте self
class MyClass
  def self.class_method
    # body
  end
  
  # Для множества методов класса
  class << self
    def first_class_method
      # body
    end
    
    def second_class_method
      # body
    end
  end
end

# ❌ НЕПРАВИЛЬНО
class MyClass
  def MyClass.class_method
    # body
  end
end
```

### Вызов методов класса внутри класса
```ruby
# ✅ ПРАВИЛЬНО - опускайте self или имя класса
class TestClass
  def self.call(param)
    new(param).process
  end
  
  def self.create(options)
    build(options).tap(&:save)
  end
  
  private_class_method def self.build(options)
    new(options)
  end
end
```

## Модификаторы доступа

### Расположение и форматирование
```ruby
# ✅ ПРАВИЛЬНО
class SomeClass
  def public_method
    # body
  end
  
  protected
  
  def protected_method
    # body
  end
  
  private
  
  def private_method
    # body
  end
  
  def another_private_method
    # body
  end
end
```

### Приватные методы класса
```ruby
# ✅ ПРАВИЛЬНО
class MyClass
  class << self
    def public_class_method
      private_class_method
    end
    
    private
    
    def private_class_method
      # body
    end
  end
end

# Альтернатива
class MyClass
  def self.public_class_method
    private_class_method
  end
  
  private_class_method def self.private_class_method
    # body
  end
end
```

## Специальные методы

### super
```ruby
# ✅ ПРАВИЛЬНО - всегда используйте скобки с аргументами
class Child < Parent
  def initialize(name, age)
    super(name, age)
    @special = true
  end
  
  # super без скобок передает все аргументы
  def process
    super
  end
  
  # super() вызывает без аргументов
  def calculate
    super() + 10
  end
end
```

### method_missing
```ruby
# ✅ ПРАВИЛЬНО - всегда определяйте respond_to_missing?
class DynamicModel
  def method_missing(method_name, *args, &block)
    if method_name.to_s.start_with?('find_by_')
      # dynamic finder logic
    else
      super
    end
  end
  
  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('find_by_') || super
  end
end
```

## Алиасы методов

### В классах
```ruby
# ✅ ПРАВИЛЬНО - используйте alias для лексической области
class Westerner
  def first_name
    @names.first
  end
  
  alias given_name first_name
end
```

### В модулях и runtime
```ruby
# ✅ ПРАВИЛЬНО - используйте alias_method для динамических алиасов
module Mononymous
  def self.included(other)
    other.class_eval do
      alias_method :full_name, :given_name
    end
  end
end
```

## Рекомендации для Claude Code

1. **Малые методы** - каждый метод должен делать одну вещь
2. **Описательные имена** - имя метода должно четко говорить, что он делает
3. **Чистые методы** - минимизируйте побочные эффекты
4. **Документирование** - добавляйте YARD комментарии для публичных методов
5. **Тестируемость** - пишите методы, которые легко тестировать
