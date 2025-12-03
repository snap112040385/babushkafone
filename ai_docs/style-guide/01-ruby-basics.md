# Ruby Basics - Основы форматирования и синтаксиса

## Кодировка и форматирование

### Кодировка файлов
```ruby
# Используйте UTF-8 (по умолчанию с Ruby 2.0+)
# Явное указание не требуется
```

### Отступы
```ruby
# ✅ ПРАВИЛЬНО - 2 пробела
def some_method
  do_something
end

# ❌ НЕПРАВИЛЬНО - 4 пробела или табы
def some_method
    do_something
end
```

### Максимальная длина строки
- **80 символов** - рекомендуемый максимум
- **100 символов** - допустимо для сложных выражений
- Настройте редактор для визуализации границы

### Окончания строк
- Используйте Unix-style (LF)
- Настройте Git: `git config core.autocrlf true`
- Каждый файл должен заканчиваться новой строкой

### Пробелы в конце строк
```ruby
# ❌ НЕПРАВИЛЬНО - пробелы в конце
some_method·· 
  
# ✅ ПРАВИЛЬНО
some_method
```

## Пробелы и операторы

### Вокруг операторов
```ruby
# ✅ ПРАВИЛЬНО
sum = 1 + 2
a, b = 1, 2
class FooError < StandardError; end

# ❌ НЕПРАВИЛЬНО
sum=1+2
a,b=1,2
class FooError<StandardError;end
```

### Исключения для пробелов
```ruby
# Экспоненциальный оператор
e = M * c**2

# Рациональные литералы
o_scale = 1/48r

# Safe navigation
foo&.bar
```

### Скобки и фигурные скобки
```ruby
# ✅ ПРАВИЛЬНО
some(arg).other
[1, 2, 3].each { |e| puts e }
{ one: 1, two: 2 }

# ❌ НЕПРАВИЛЬНО
some( arg ).other
[ 1, 2, 3 ].each{|e| puts e}
```

### Интерполяция строк
```ruby
# ✅ ПРАВИЛЬНО
"From: #{user.first_name}, #{user.last_name}"

# ❌ НЕПРАВИЛЬНО
"From: #{ user.first_name }, #{ user.last_name }"
```

## Пустые строки

### Между методами
```ruby
# ✅ ПРАВИЛЬНО
def some_method
  data = initialize(options)
  data.manipulate!
  data.result
end

def some_other_method
  result
end
```

### После include/extend
```ruby
# ✅ ПРАВИЛЬНО
class Foo
  extend SomeModule
  include AnotherModule
  
  attr_reader :foo
  
  def initialize
    # code
  end
end
```

### Вокруг access modifiers
```ruby
# ✅ ПРАВИЛЬНО
class Foo
  def public_method
    # code
  end
  
  private
  
  def private_method
    # code
  end
end
```

## Выражения и операторы

### Одно выражение на строку
```ruby
# ✅ ПРАВИЛЬНО
puts 'foo'
puts 'bar'

# ❌ НЕПРАВИЛЬНО
puts 'foo'; puts 'bar'
```

### Точки с запятой
```ruby
# ❌ НЕПРАВИЛЬНО - не используйте ; в конце выражений
puts 'foobar';

# ✅ ПРАВИЛЬНО
puts 'foobar'
```

### Вызов операторных методов
```ruby
# ✅ ПРАВИЛЬНО
num + 42

# ❌ НЕПРАВИЛЬНО
num.+ 42
```

## Многострочные конструкции

### Выравнивание при присваивании
```ruby
# ✅ ПРАВИЛЬНО
kind = case year
       when 1850..1889 then 'Blues'
       when 1890..1909 then 'Ragtime'
       when 1910..1929 then 'New Orleans Jazz'
       else 'Jazz'
       end

# Альтернативный стиль
kind =
  case year
  when 1850..1889 then 'Blues'
  when 1890..1909 then 'Ragtime'
  else 'Jazz'
  end
```

### Цепочки методов
```ruby
# ✅ Стиль 1 - точка на новой строке
one.two.three
  .four
  .five

# ✅ Стиль 2 - точка на той же строке
one.two.three.
  four.
  five
```

### Аргументы методов
```ruby
# ✅ ПРАВИЛЬНО - выравнивание
def send_mail(source)
  Mailer.deliver(to: 'bob@example.com',
                 from: 'us@example.com',
                 subject: 'Important message',
                 body: source.text)
end

# ✅ ПРАВИЛЬНО - обычный отступ
def send_mail(source)
  Mailer.deliver(
    to: 'bob@example.com',
    from: 'us@example.com',
    subject: 'Important message',
    body: source.text
  )
end
```

## Комментарии

### Формат комментариев
```ruby
# ✅ ПРАВИЛЬНО - пробел после #
# This is a comment

# ❌ НЕПРАВИЛЬНО
#This is a comment
```

### Аннотации
```ruby
# TODO: добавить обработку ошибок
# FIXME: исправить утечку памяти
# OPTIMIZE: можно ускорить алгоритм
# HACK: временное решение
# REVIEW: нужна проверка логики
# NOTE: важное замечание
```

### Расположение аннотаций
```ruby
# ✅ ПРАВИЛЬНО
def bar
  # FIXME: Периодически падает с версии 3.2.1
  baz(:quux)
end

# ❌ НЕПРАВИЛЬНО
def bar
  baz(:quux) # FIXME: Периодически падает с версии 3.2.1
end
```

## Magic Comments

### Порядок
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: utf-8

# Документация класса
class Person
  # code
end
```

### Отделение от кода
```ruby
# frozen_string_literal: true

# Пустая строка обязательна
class Person
  # code
end
```

## Рекомендации Claude Code

При работе с Claude Code:
1. Всегда используйте `# frozen_string_literal: true`
2. Поддерживайте консистентные отступы
3. Не смешивайте табы и пробелы
4. Используйте автоформатирование через RuboCop
