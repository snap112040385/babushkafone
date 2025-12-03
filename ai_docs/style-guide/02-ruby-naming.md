# Ruby Naming - Соглашения об именовании

## Общие правила

### Язык идентификаторов
```ruby
# ✅ ПРАВИЛЬНО - английский язык
salary = 1_000
user_name = 'John'

# ❌ НЕПРАВИЛЬНО - транслитерация или кириллица
zaplata = 1_000
заплата = 1_000
```

## Стили именования

### snake_case для методов и переменных
```ruby
# ✅ ПРАВИЛЬНО
some_var = 5
def some_method
  local_variable = 10
end

# ❌ НЕПРАВИЛЬНО
someVar = 5
def someMethod
  localVariable = 10
end
```

### CamelCase для классов и модулей
```ruby
# ✅ ПРАВИЛЬНО
class SomeClass
  # code
end

module SomeModule
  # code
end

# Аббревиатуры пишутся заглавными
class HTTPClient
  # code
end

class XMLParser
  # code
end

# ❌ НЕПРАВИЛЬНО
class Some_Class
  # code
end

class XmlParser  # XML должно быть заглавными
  # code
end
```

### SCREAMING_SNAKE_CASE для констант
```ruby
# ✅ ПРАВИЛЬНО
SOME_CONSTANT = 20
MAX_RETRIES = 3
API_VERSION = 'v1'

# ❌ НЕПРАВИЛЬНО
SomeConst = 5
some_const = 5
```

### Символы
```ruby
# ✅ ПРАВИЛЬНО
:some_symbol
:status_ok
:http_error

# ❌ НЕПРАВИЛЬНО
:'some symbol'
:SomeSymbol
:someSymbol
```

## Файлы и директории

### Имена файлов
```ruby
# ✅ ПРАВИЛЬНО
hello_world.rb
user_controller.rb
api_client.rb

# ❌ НЕПРАВИЛЬНО
HelloWorld.rb
helloWorld.rb
hello-world.rb
```

### Структура директорий
```ruby
# ✅ ПРАВИЛЬНО
lib/hello_world/hello_world.rb
app/models/user_account.rb

# ❌ НЕПРАВИЛЬНО
lib/HelloWorld/HelloWorld.rb
app/models/UserAccount.rb
```

### Соответствие имени файла и класса
```ruby
# Файл: user_account.rb
class UserAccount
  # code
end

# Файл: api/http_client.rb
module API
  class HTTPClient
    # code
  end
end
```

## Методы

### Предикаты (возвращают boolean)
```ruby
# ✅ ПРАВИЛЬНО
def empty?
  @items.count == 0
end

def valid?
  validate_internal_state
end

def can_edit?
  permissions.include?(:edit)
end

# ❌ НЕПРАВИЛЬНО
def is_empty
  @items.count == 0
end

def does_validate
  validate_internal_state
end
```

### Опасные методы (изменяют состояние)
```ruby
# ✅ ПРАВИЛЬНО - есть безопасная версия
def save
  # возвращает boolean
end

def save!
  # выбрасывает исключение
end

def flatten
  # возвращает новый массив
end

def flatten!
  # изменяет текущий массив
end

# ❌ НЕПРАВИЛЬНО - нет безопасной версии
def update!
  # изменяет объект
end
```

### Геттеры и сеттеры
```ruby
# ✅ ПРАВИЛЬНО - Ruby style
class Person
  attr_reader :name
  attr_writer :age
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def full_name=(value)
    @first_name, @last_name = value.split(' ')
  end
end

# ❌ НЕПРАВИЛЬНО - Java style
class Person
  def get_name
    @name
  end
  
  def set_name(value)
    @name = value
  end
end
```

## Переменные

### Локальные переменные и параметры
```ruby
# ✅ ПРАВИЛЬНО
def calculate_total(base_price, tax_rate)
  subtotal = base_price * quantity
  tax_amount = subtotal * tax_rate
  subtotal + tax_amount
end
```

### Переменные экземпляра
```ruby
# ✅ ПРАВИЛЬНО
class User
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end
end
```

### Переменные класса (избегайте!)
```ruby
# ❌ НЕПРАВИЛЬНО - проблемы с наследованием
class Parent
  @@count = 0
end

# ✅ ПРАВИЛЬНО - используйте переменные экземпляра класса
class Parent
  @count = 0
  
  class << self
    attr_accessor :count
  end
end
```

### Глобальные переменные (избегайте!)
```ruby
# ❌ НЕПРАВИЛЬНО
$global_config = {}

# ✅ ПРАВИЛЬНО - используйте модули или классы
module Config
  @settings = {}
  
  def self.settings
    @settings
  end
end
```

## Специальные случаи

### Числа в именах
```ruby
# ✅ ПРАВИЛЬНО - число без подчеркивания
some_var1 = 1
var10 = 10
def some_method1
  # code
end

# ❌ НЕПРАВИЛЬНО - отделение числа подчеркиванием
some_var_1 = 1
var_10 = 10
def some_method_1
  # code
end
```

### Неиспользуемые переменные
```ruby
# ✅ ПРАВИЛЬНО - префикс _ для неиспользуемых
result = hash.map { |_key, value| value + 1 }

def something(x)
  _unused_var, used_var = something_else(x)
  # используем только used_var
end

# Можно использовать просто _
result = hash.map { |_, v| v + 1 }
```

### Параметр other в бинарных операторах
```ruby
# ✅ ПРАВИЛЬНО
def +(other)
  value + other.value
end

def ==(other)
  value == other.value
end

# Для несимметричных операций используйте описательные имена
def <<(item)
  @internal << item
end

def [](index)
  @items[index]
end
```

## Rails-специфичные соглашения

### Модели
```ruby
# ✅ ПРАВИЛЬНО - единственное число
class User < ApplicationRecord
end

class OrderItem < ApplicationRecord
end
```

### Контроллеры
```ruby
# ✅ ПРАВИЛЬНО - множественное число + Controller
class UsersController < ApplicationController
end

class OrderItemsController < ApplicationController
end
```

### Хелперы
```ruby
# ✅ ПРАВИЛЬНО
module UsersHelper
end

module ApplicationHelper
end
```

## Рекомендации для Claude Code

1. **Консистентность** - придерживайтесь одного стиля во всем проекте
2. **Описательность** - имена должны четко описывать назначение
3. **Длина** - избегайте слишком коротких (a, b, x) и слишком длинных имен
4. **Контекст** - учитывайте контекст использования при выборе имени
