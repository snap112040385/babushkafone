# Ruby Blocks, Procs & Lambdas - Блоки, процедуры и лямбды

## Блоки

### Однострочные vs многострочные
```ruby
# ✅ ПРАВИЛЬНО - {} для однострочных
names.map { |name| name.upcase }
[1, 2, 3].select { |n| n.odd? }

# ✅ ПРАВИЛЬНО - do...end для многострочных
names.each do |name|
  formatted = name.strip.downcase
  puts formatted
end

# ❌ НЕПРАВИЛЬНО
names.each { |name|
  formatted = name.strip.downcase
  puts formatted
}

names.map do |name| name.upcase end
```

### Цепочки методов с блоками
```ruby
# ✅ ПРАВИЛЬНО - {} для цепочек
users
  .select { |u| u.active? }
  .map { |u| u.email }
  .uniq

# ❌ НЕПРАВИЛЬНО - do...end ломает цепочку
users
  .select do |u|
    u.active?
  end.map { |u| u.email }  # выглядит странно
```

### Параметры блоков
```ruby
# ✅ ПРАВИЛЬНО - описательные имена
users.each { |user| send_email(user) }
hash.each { |key, value| process(key, value) }

# ✅ ПРАВИЛЬНО - короткие имена для простых операций
[1, 2, 3].map { |n| n * 2 }
array.select { |x| x > 0 }

# Неиспользуемые параметры - префикс _
hash.map { |_key, value| value * 2 }
array.each_with_index { |_item, index| puts index }
```

### Блоки с return
```ruby
# ⚠️ ВНИМАНИЕ - return выходит из метода, не из блока!
def process_items(items)
  items.each do |item|
    return if item.nil?  # выйдет из process_items!
    process(item)
  end
  
  puts "All processed"  # может не выполниться
end

# ✅ ПРАВИЛЬНО - используйте next для пропуска итерации
def process_items(items)
  items.each do |item|
    next if item.nil?
    process(item)
  end
  
  puts "All processed"
end
```

### Передача блоков
```ruby
# ✅ ПРАВИЛЬНО - явная передача блока
def with_timing(&block)
  start = Time.now
  result = block.call
  puts "Took #{Time.now - start} seconds"
  result
end

# ✅ ПРАВИЛЬНО - yield
def with_timing
  start = Time.now
  result = yield
  puts "Took #{Time.now - start} seconds"
  result
end

# Проверка наличия блока
def maybe_yield
  yield if block_given?
end
```

### Ruby 3.1+ анонимная переадресация блоков
```ruby
# ✅ ПРАВИЛЬНО - используйте & для переадресации
def logged_operation(&)
  log_start
  result = perform_operation(&)
  log_end
  result
end

# ❌ НЕПРАВИЛЬНО - именованный блок без использования
def logged_operation(&block)
  log_start
  result = perform_operation(&block)
  log_end
  result
end
```

## Proc

### Создание Proc
```ruby
# ✅ ПРАВИЛЬНО - используйте proc
my_proc = proc { |x| x * 2 }
handler = proc do |event|
  log(event)
  process(event)
end

# ❌ НЕПРАВИЛЬНО
my_proc = Proc.new { |x| x * 2 }
```

### Вызов Proc
```ruby
my_proc = proc { |x| x * 2 }

# ✅ ПРАВИЛЬНО - используйте call
my_proc.call(5)

# ❌ НЕПРАВИЛЬНО - альтернативные синтаксисы
my_proc[5]      # похоже на доступ к массиву
my_proc.(5)     # непривычный синтаксис
my_proc === 5   # для case выражений
```

### Proc в качестве блока
```ruby
# ✅ ПРАВИЛЬНО - & для преобразования в блок
processor = proc { |x| x.upcase }
names.map(&processor)

# Symbol#to_proc
names.map(&:upcase)
# эквивалентно
names.map { |name| name.upcase }
```

## Lambda

### Создание lambda
```ruby
# ✅ ПРАВИЛЬНО - stabby lambda для однострочных
add = ->(a, b) { a + b }
validate = ->(value) { value.positive? }

# ✅ ПРАВИЛЬНО - lambda для многострочных
process = lambda do |data|
  cleaned = clean_data(data)
  validated = validate_data(cleaned)
  transform_data(validated)
end

# ❌ НЕПРАВИЛЬНО - смешивание стилей
process = ->(data) do
  # многострочный код
end
```

### Lambda параметры
```ruby
# ✅ ПРАВИЛЬНО - всегда используйте скобки с параметрами
multiply = ->(x, y) { x * y }

# ✅ ПРАВИЛЬНО - опускайте для lambda без параметров
greet = -> { puts 'Hello!' }

# ❌ НЕПРАВИЛЬНО
multiply = -> x, y { x * y }
greet = ->() { puts 'Hello!' }
```

## Proc vs Lambda

### Различия в проверке аргументов
```ruby
# Lambda проверяет количество аргументов
my_lambda = ->(x, y) { x + y }
my_lambda.call(1, 2)  # => 3
my_lambda.call(1)     # ArgumentError!

# Proc более гибкий
my_proc = proc { |x, y| x + y }
my_proc.call(1, 2)    # => 3
my_proc.call(1)       # => TypeError (nil + ?)
my_proc.call(1, 2, 3) # => 3 (игнорирует лишние)
```

### Различия в return
```ruby
def test_lambda
  my_lambda = -> { return 'from lambda' }
  my_lambda.call
  'from method'
end

def test_proc
  my_proc = proc { return 'from proc' }
  my_proc.call  # выйдет из метода!
  'from method'
end

test_lambda  # => 'from method'
test_proc    # => 'from proc'
```

### Когда использовать
```ruby
# ✅ Lambda - когда нужна строгость
# - Проверка аргументов
# - Изолированный return
# - Функциональное программирование

validators = {
  email: ->(v) { v.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i) },
  phone: ->(v) { v.match?(/\A\d{10}\z/) }
}

# ✅ Proc - для гибкости
# - DSL
# - Callbacks
# - Когда количество аргументов может варьироваться

callbacks = {
  before: proc { |*args| log("Before", *args) },
  after: proc { |*args| log("After", *args) }
}
```

## Method объекты

### Получение Method объектов
```ruby
# Получение метода как объекта
str = "hello"
upcase_method = str.method(:upcase)
upcase_method.call  # => "HELLO"

# Unbound методы
unbound = String.instance_method(:upcase)
bound = unbound.bind("hello")
bound.call  # => "HELLO"
```

### Использование Method в функциональном стиле
```ruby
# ✅ Композиция функций
class Pipeline
  def initialize
    @steps = []
  end
  
  def add_step(callable)
    @steps << callable
    self
  end
  
  def process(input)
    @steps.reduce(input) { |data, step| step.call(data) }
  end
end

pipeline = Pipeline.new
  .add_step(->(x) { x.strip })
  .add_step(:downcase.to_proc)
  .add_step(->(x) { x.gsub(' ', '_') })

pipeline.process("  Hello World  ")  # => "hello_world"
```

## Curry и частичное применение

```ruby
# Curry - преобразование функции с множеством аргументов
add = ->(a, b, c) { a + b + c }
curried = add.curry

add_one = curried.call(1)
add_one_two = add_one.call(2)
result = add_one_two.call(3)  # => 6

# Или сразу
curried.(1).(2).(3)  # => 6

# Частичное применение
multiply = ->(x, y) { x * y }
double = multiply.curry.(2)
double.(5)  # => 10
```

## Паттерны использования

### Callbacks и хуки
```ruby
class EventEmitter
  def initialize
    @handlers = Hash.new { |h, k| h[k] = [] }
  end
  
  def on(event, &block)
    @handlers[event] << block
  end
  
  def emit(event, *args)
    @handlers[event].each { |handler| handler.call(*args) }
  end
end

emitter = EventEmitter.new
emitter.on(:click) { |x, y| puts "Clicked at #{x}, #{y}" }
emitter.on(:click) { |x, y| log_click(x, y) }
emitter.emit(:click, 100, 200)
```

### DSL с блоками
```ruby
class Config
  def initialize(&block)
    @settings = {}
    instance_eval(&block) if block_given?
  end
  
  def set(key, value)
    @settings[key] = value
  end
  
  def get(key)
    @settings[key]
  end
end

config = Config.new do
  set :host, 'localhost'
  set :port, 3000
  set :ssl, true
end
```

### Lazy evaluation
```ruby
class LazyValue
  def initialize(&block)
    @block = block
    @evaluated = false
    @value = nil
  end
  
  def value
    unless @evaluated
      @value = @block.call
      @evaluated = true
    end
    @value
  end
end

expensive_calculation = LazyValue.new do
  puts "Calculating..."
  sleep(2)
  42
end

# Вычисляется только при первом вызове
expensive_calculation.value  # => Calculating... (ждет 2 сек) => 42
expensive_calculation.value  # => 42 (сразу)
```

## Вложенные методы (избегайте)

```ruby
# ❌ НЕПРАВИЛЬНО - вложенные def
def outer
  def inner  # Определяется в том же классе!
    'inner'
  end
  
  inner
end

# ✅ ПРАВИЛЬНО - используйте lambda
def outer
  inner = -> { 'inner' }
  inner.call
end
```

## Рекомендации для Claude Code

1. **{} vs do...end** - {} для однострочных и цепочек, do...end для многострочных
2. **Lambda для функций** - используйте lambda когда нужна функциональная семантика
3. **Proc для DSL** - используйте proc для гибких callbacks и DSL
4. **& для преобразований** - используйте & для преобразования между блоками и proc
5. **Избегайте сложности** - не злоупотребляйте метапрограммированием
