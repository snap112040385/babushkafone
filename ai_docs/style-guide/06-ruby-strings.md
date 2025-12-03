# Ruby Strings - Работа со строками

## Кавычки

### Выбор типа кавычек

#### Стиль 1: Одинарные кавычки по умолчанию
```ruby
# ✅ ПРАВИЛЬНО - одинарные для простых строк
name = 'Bozhidar'
message = 'Hello, world!'

# ✅ ПРАВИЛЬНО - двойные когда нужна интерполяция или escape-последовательности
greeting = "Hello, #{name}!"
multiline = "First line\nSecond line"
quote = "He said, 'Hello'"

# ❌ НЕПРАВИЛЬНО
name = "Bozhidar"  # нет интерполяции
```

#### Стиль 2: Двойные кавычки по умолчанию
```ruby
# ✅ ПРАВИЛЬНО - консистентное использование двойных
name = "Bozhidar"
message = "Hello, world!"

# ✅ ПРАВИЛЬНО - одинарные для строк с кавычками
quote = 'He said, "Hello"'
```

## Интерполяция

### Базовая интерполяция
```ruby
# ✅ ПРАВИЛЬНО
"Hello, #{user.name}!"
"Total: #{price * quantity}"
"User ##{user.id}"

# ❌ НЕПРАВИЛЬНО - конкатенация
'Hello, ' + user.name + '!'
```

### Фигурные скобки обязательны
```ruby
# ✅ ПРАВИЛЬНО - всегда используйте {}
"Name: #{@name}"
"Price: #{@price}"

# ❌ НЕПРАВИЛЬНО - без скобок (хоть и работает)
"Name: #@name"
"Price: #@price"
```

### Не вызывайте to_s явно
```ruby
# ✅ ПРАВИЛЬНО - to_s вызывается автоматически
"Result: #{result}"
"Count: #{items.count}"

# ❌ НЕПРАВИЛЬНО
"Result: #{result.to_s}"
"Count: #{items.count.to_s}"
```

## Форматирование

### sprintf/format
```ruby
# ✅ ПРАВИЛЬНО - используйте format или sprintf
format('Hello, %s', name)
sprintf('%d items in cart', count)

# Именованные параметры
format('Hello, %<name>s! You have %<count>d messages', 
       name: 'John', count: 5)

# ❌ НЕПРАВИЛЬНО - криптичный %
'%s has %d items' % [name, count]
```

### Многострочные строки
```ruby
# ✅ ПРАВИЛЬНО - heredoc для многострочного текста
description = <<~TEXT
  This is a long description
  that spans multiple lines
  with proper indentation.
TEXT

# ✅ ПРАВИЛЬНО - \ для продолжения строки без переносов
long_string = "This is a very long string that would normally " \
              "be too long to fit on a single line, so we split it " \
              "across multiple lines for better readability."

# ❌ НЕПРАВИЛЬНО - конкатенация
long_string = "This is a very long string " +
              "that spans multiple lines " +
              "using concatenation"
```

## Heredoc

### Squiggly heredoc (<<~)
```ruby
# ✅ ПРАВИЛЬНО - убирает лишние отступы
def generate_email
  <<~EMAIL
    Dear Customer,
    
    Thank you for your purchase.
    
    Best regards,
    The Team
  EMAIL
end

# ❌ НЕПРАВИЛЬНО - сохраняет отступы
def generate_email
  <<-EMAIL
    Dear Customer,
    
    Thank you for your purchase.
  EMAIL
end
```

### Описательные делимитеры
```ruby
# ✅ ПРАВИЛЬНО - понятные имена делимитеров
sql = <<~SQL
  SELECT * FROM users
  WHERE active = true
  ORDER BY created_at DESC
SQL

html = <<~HTML
  <div class="container">
    <h1>Welcome</h1>
  </div>
HTML

# ❌ НЕПРАВИЛЬНО - непонятные делимитеры
sql = <<~EOF
  SELECT * FROM users
EOF
```

## Операции со строками

### Конкатенация
```ruby
# ✅ ПРАВИЛЬНО - << для построения больших строк
html = ''
html << '<h1>Title</h1>'
html << '<p>Content</p>'

# ❌ НЕПРАВИЛЬНО - += создает новые объекты
html = ''
html += '<h1>Title</h1>'
html += '<p>Content</p>'
```

### Замены
```ruby
# ✅ ПРАВИЛЬНО - специализированные методы
url.sub('http://', 'https://')      # одна замена
str.tr('-', '_')                    # замена символов
str.delete(' ')                     # удаление
str.squeeze(' ')                    # схлопывание повторов

# ❌ НЕПРАВИЛЬНО - gsub для простых случаев
url.gsub('http://', 'https://')    # используйте sub
str.gsub('-', '_')                 # используйте tr
str.gsub(' ', '')                  # используйте delete
```

### Разбиение и объединение
```ruby
# ✅ ПРАВИЛЬНО
'hello'.chars           # ['h', 'e', 'l', 'l', 'o']
'one,two,three'.split(',')
['one', 'two', 'three'].join(', ')

# ❌ НЕПРАВИЛЬНО
'hello'.split('')       # используйте chars
'hello'.split(//)       # используйте chars
```

## Проверки и поиск

### Методы проверки
```ruby
# ✅ ПРАВИЛЬНО - специализированные методы
str.empty?
str.include?('substring')
str.start_with?('http://')
str.end_with?('.rb')
str.match?(/pattern/)

# ❌ НЕПРАВИЛЬНО - регулярки для простых проверок
str =~ /^$/            # используйте empty?
str =~ /substring/     # используйте include?
str =~ /^http:\/\//    # используйте start_with?
```

### Case-insensitive сравнение
```ruby
# ✅ ПРАВИЛЬНО
str1.casecmp(str2).zero?
str1.casecmp?(str2)  # Ruby 2.4+

# ❌ НЕПРАВИЛЬНО - создает новые строки
str1.downcase == str2.downcase
```

## Обработка строк

### strip, chomp, chop
```ruby
# strip - удаляет пробелы с обоих концов
"  hello  ".strip  # => "hello"

# lstrip/rstrip - удаляет слева/справа
"  hello  ".lstrip  # => "hello  "
"  hello  ".rstrip  # => "  hello"

# chomp - удаляет символ новой строки
"hello\n".chomp     # => "hello"
"hello".chomp       # => "hello"

# chop - удаляет последний символ
"hello".chop        # => "hell"
```

### Изменение регистра
```ruby
str.upcase      # ВСЕ ЗАГЛАВНЫЕ
str.downcase    # все строчные
str.capitalize  # Первая заглавная
str.swapcase    # иНВЕРСИЯ рЕГИСТРА
```

## Кодировка

### UTF-8
```ruby
# ✅ По умолчанию с Ruby 2.0+
# Явное указание обычно не требуется

# Проверка кодировки
str.encoding        # => #<Encoding:UTF-8>
str.valid_encoding? # => true

# Конвертация
str.encode('UTF-8')
str.force_encoding('UTF-8')
```

## Регулярные выражения со строками

### match vs =~
```ruby
# ✅ ПРАВИЛЬНО - match? для проверки (Ruby 2.4+)
if email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  # valid email
end

# Для извлечения данных
if match = string.match(/(\d+)-(\d+)/)
  start_num = match[1]
  end_num = match[2]
end

# ❌ НЕПРАВИЛЬНО для простой проверки
if email =~ /pattern/  # создает глобальные переменные $~, $1, etc.
  # code
end
```

### scan для множественных совпадений
```ruby
# Извлечь все числа
"abc 123 def 456".scan(/\d+/)  # => ["123", "456"]

# С группами
"name:John age:30".scan(/(\w+):(\w+)/)
# => [["name", "John"], ["age", "30"]]
```

## Символы vs Строки

### Когда использовать символы
```ruby
# ✅ Символы - для идентификаторов
{ status: :active, role: :admin }
send(:method_name)

# ✅ Строки - для текстовых данных
{ name: "John", email: "john@example.com" }
```

## Frozen строки

### frozen_string_literal
```ruby
# frozen_string_literal: true

# Все строковые литералы заморожены
str = "hello"  # замороженная строка
str << " world"  # RuntimeError!

# Размораживание
str = +"hello"  # или String.new("hello")
str << " world"  # OK
```

## Производительность

### Советы по оптимизации
```ruby
# ✅ Используйте frozen строки где возможно
CONSTANT = 'immutable'.freeze

# ✅ StringIO для построения больших строк
require 'stringio'
buffer = StringIO.new
buffer << "Line 1\n"
buffer << "Line 2\n"
result = buffer.string

# ✅ Избегайте создания промежуточных строк
# Плохо: str.downcase.strip.gsub(' ', '_')
# Лучше: str.strip!; str.downcase!; str.tr!(' ', '_')
```

## Рекомендации для Claude Code

1. **Консистентность кавычек** - выберите стиль и придерживайтесь его
2. **Интерполяция vs конкатенация** - всегда предпочитайте интерполяцию
3. **Правильный метод** - используйте специализированные методы (tr, sub, delete)
4. **Frozen strings** - включайте frozen_string_literal: true
5. **Heredoc для многострочных** - используйте <<~ для читаемости
