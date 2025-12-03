# Ruby Flow Control - Управление потоком выполнения

## Условные операторы

### if/unless базовое использование
```ruby
# ✅ ПРАВИЛЬНО - if для позитивных условий
if user.active?
  send_notification
end

# ✅ ПРАВИЛЬНО - unless для негативных условий
unless user.banned?
  allow_access
end

# ❌ НЕПРАВИЛЬНО - двойное отрицание
if !user.inactive?
  send_notification
end
```

### Модификаторы if/unless
```ruby
# ✅ ПРАВИЛЬНО - для однострочных выражений
send_email if user.subscribed?
return unless valid_input?

# ❌ НЕПРАВИЛЬНО - для многострочных блоков
10.times do
  # многострочный
  # блок кода
end if some_condition  # плохо!
```

### Тернарный оператор
```ruby
# ✅ ПРАВИЛЬНО - для простых условий
status = user.active? ? 'active' : 'inactive'
message = error ? error.message : 'Success'

# ❌ НЕПРАВИЛЬНО - вложенные тернарные операторы
status = user.active? ? (user.admin? ? 'admin' : 'user') : 'inactive'

# ✅ Используйте if/else для сложных случаев
status = if user.active?
           user.admin? ? 'admin' : 'user'
         else
           'inactive'
         end
```

### unless с else
```ruby
# ❌ НЕПРАВИЛЬНО - никогда не используйте unless с else
unless success?
  puts 'failure'
else
  puts 'success'
end

# ✅ ПРАВИЛЬНО - переверните логику
if success?
  puts 'success'
else
  puts 'failure'
end
```

## case выражения

### Базовое использование
```ruby
# ✅ ПРАВИЛЬНО
case status
when :draft
  'Not published'
when :published, :scheduled
  'Available'
when :archived
  'No longer available'
else
  'Unknown status'
end

# Присваивание результата
result = case value
         when 0..10 then 'low'
         when 11..20 then 'medium'
         else 'high'
         end
```

### case vs if-elsif
```ruby
# ❌ НЕПРАВИЛЬНО - повторяющиеся проверки
if status == :active
  activate_features
elsif status == :pending
  show_waiting_message
elsif status == :inactive
  deactivate_features
end

# ✅ ПРАВИЛЬНО - используйте case
case status
when :active
  activate_features
when :pending
  show_waiting_message
when :inactive
  deactivate_features
end
```

### Pattern matching (Ruby 2.7+)
```ruby
# ✅ ПРАВИЛЬНО - современный pattern matching
case response
in { status: 200, body: }
  process_success(body)
in { status: 404 }
  handle_not_found
in { status: 500.. => status }
  handle_server_error(status)
else
  handle_unknown_response
end
```

## Циклы

### Итераторы vs циклы
```ruby
# ✅ ПРАВИЛЬНО - используйте итераторы
array.each { |item| process(item) }
5.times { puts 'Hello' }
1.upto(10) { |i| puts i }

# ❌ НЕПРАВИЛЬНО - избегайте for
for item in array
  process(item)
end
```

### while/until
```ruby
# ✅ ПРАВИЛЬНО - для простых случаев
while connection.active?
  process_data
end

until queue.empty?
  process_next_item
end

# Модификаторы для однострочных
process_data while has_more_data?
```

### Бесконечные циклы
```ruby
# ✅ ПРАВИЛЬНО - используйте loop
loop do
  data = fetch_data
  break unless data
  process(data)
end

# ❌ НЕПРАВИЛЬНО
while true
  # code
end
```

### break, next, redo
```ruby
# break - выход из цикла
loop do
  input = gets.chomp
  break if input == 'quit'
  process(input)
end

# next - переход к следующей итерации
[1, 2, 3, 4, 5].each do |n|
  next if n.even?
  puts n  # только нечетные
end

# redo - повтор текущей итерации
attempts = 0
[1, 2, 3].each do |n|
  attempts += 1
  puts "Processing #{n}, attempt #{attempts}"
  redo if attempts < 3 && n == 2
  attempts = 0
end
```

## Guard Clauses (защитные условия)

### Ранний выход
```ruby
# ✅ ПРАВИЛЬНО - guard clauses вверху
def process_order(order)
  return unless order
  return if order.cancelled?
  return unless order.items.any?
  
  # основная логика
  calculate_total(order)
  apply_discount(order)
  charge_customer(order)
end

# ❌ НЕПРАВИЛЬНО - вложенные условия
def process_order(order)
  if order
    if !order.cancelled?
      if order.items.any?
        # основная логика
      end
    end
  end
end
```

### В циклах
```ruby
# ✅ ПРАВИЛЬНО - next вместо вложенных if
users.each do |user|
  next unless user.active?
  next if user.suspended?
  
  send_newsletter(user)
end

# ❌ НЕПРАВИЛЬНО
users.each do |user|
  if user.active?
    unless user.suspended?
      send_newsletter(user)
    end
  end
end
```

## Логические операторы

### && и || vs and и or
```ruby
# ✅ ПРАВИЛЬНО - && и || для логических выражений
if user.active? && user.verified?
  grant_access
end

status = user.admin? || user.moderator?

# ✅ ПРАВИЛЬНО - and и or для control flow
user.save or raise "Could not save"
find_user and send_email

# ❌ НЕПРАВИЛЬНО - смешивание назначений
# and/or имеют очень низкий приоритет!
result = user.save or raise "Error"  # не работает как ожидается!
```

### Безопасная навигация (&.)
```ruby
# ✅ ПРАВИЛЬНО - для nullable объектов
user&.address&.city

# ❌ НЕПРАВИЛЬНО - длинные цепочки
user&.account&.subscription&.plan&.features&.first

# ✅ Лучше - явная проверка или рефакторинг
if user && user.account.active?
  user.account.subscription.plan
end
```

### Двойное отрицание (!!)
```ruby
# ✅ OK - когда нужно именно true/false
def admin?
  !!current_user&.admin_role
end

# ❌ НЕПРАВИЛЬНО - в условиях
if !!user
  # избыточно, Ruby уже проверяет truthiness
end
```

## Присваивание в условиях

### Safe assignment
```ruby
# ✅ ПРАВИЛЬНО - с круглыми скобками
if (match = string.match(/pattern/))
  use_match_data(match)
end

while (line = file.gets)
  process_line(line)
end

# ❌ НЕПРАВИЛЬНО - без скобок вызовет warning
if match = string.match(/pattern/)
  use_match_data(match)
end
```

## Операторы присваивания

### ||= для инициализации
```ruby
# ✅ ПРАВИЛЬНО - инициализация nil или false значений
@connection ||= establish_connection
options[:timeout] ||= 30

# ⚠️ ОСТОРОЖНО - перезапишет false
# Если boolean может быть false:
@enabled = true if @enabled.nil?
```

### &&= для условного изменения
```ruby
# ✅ ПРАВИЛЬНО - изменить только если существует
name &&= name.downcase
user &&= user.active? ? user : nil

# Эквивалентно
name = name.downcase if name
```

## BEGIN/END блоки

```ruby
# ❌ ИЗБЕГАЙТЕ BEGIN блоков
BEGIN {
  puts "This runs first"
}

# ❌ ИЗБЕГАЙТЕ END блоков
END {
  puts "This runs last"
}

# ✅ ПРАВИЛЬНО - используйте at_exit
at_exit do
  cleanup_resources
  puts "Goodbye!"
end
```

## Обработка nil

### Паттерны работы с nil
```ruby
# Использование || для дефолтов
name = user.name || 'Anonymous'

# Безопасная навигация
city = user&.address&.city

# fetch с дефолтом
value = hash.fetch(:key, 'default')

# Множественное присваивание с дефолтами
name, age = [user.name, user.age]
name ||= 'Unknown'
age ||= 0
```

## Метапрограммирование и control flow

### send и public_send
```ruby
# ✅ ПРАВИЛЬНО - public_send для безопасности
object.public_send(method_name, args)

# Только если нужен доступ к private методам
object.send(:private_method)
```

### respond_to? проверки
```ruby
# ✅ ПРАВИЛЬНО - проверка перед вызовом
if object.respond_to?(:method_name)
  object.method_name
end

# Duck typing
def process(object)
  return unless object.respond_to?(:to_s)
  puts object.to_s
end
```

## Рекомендации для Claude Code

1. **Guard clauses** - используйте для раннего выхода и уменьшения вложенности
2. **case over if-elsif** - для множественных проверок одного значения
3. **Итераторы over циклы** - предпочитайте функциональный стиль
4. **Явность** - избегайте слишком умного кода
5. **Nil-безопасность** - всегда учитывайте возможность nil значений
