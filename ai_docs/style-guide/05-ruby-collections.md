# Ruby Collections - Работа с коллекциями

## Создание коллекций

### Литералы vs конструкторы
```ruby
# ✅ ПРАВИЛЬНО - используйте литералы
arr = []
hash = {}

# ✅ OK - когда нужны параметры конструктора
arr = Array.new(10)  # массив из 10 nil
hash = Hash.new(0)   # хеш с дефолтным значением 0

# ❌ НЕПРАВИЛЬНО
arr = Array.new
hash = Hash.new
```

### Массивы слов и символов
```ruby
# ✅ ПРАВИЛЬНО - %w для слов
STATES = %w[draft open closed]

# ✅ ПРАВИЛЬНО - %i для символов
ACTIONS = %i[create read update delete]

# ❌ НЕПРАВИЛЬНО
STATES = ['draft', 'open', 'closed']
ACTIONS = [:create, :read, :update, :delete]
```

## Массивы

### Доступ к элементам
```ruby
# ✅ ПРАВИЛЬНО - семантические методы
arr.first
arr.last
arr.first(3)  # первые 3 элемента
arr.last(2)   # последние 2 элемента

# ✅ OK - для присваивания
arr[0] = 'new_first'
arr[-1] = 'new_last'

# Срезы с диапазонами
arr[1..]     # от второго до конца
arr[..3]     # от начала до четвертого
arr[1..3]    # со второго по четвертый
```

### Итерация
```ruby
# ✅ ПРАВИЛЬНО
[1, 2, 3].each { |n| puts n }

# С индексом
arr.each_with_index do |item, index|
  puts "#{index}: #{item}"
end

# ❌ НЕПРАВИЛЬНО - не используйте for
for elem in arr do
  puts elem
end
```

### Трансформация
```ruby
# ✅ ПРАВИЛЬНО - функциональный стиль
numbers = [1, 2, 3, 4, 5]

# map для трансформации
doubled = numbers.map { |n| n * 2 }

# select для фильтрации
evens = numbers.select(&:even?)

# reject для исключения
odds = numbers.reject(&:even?)

# reduce для агрегации
sum = numbers.reduce(0, :+)

# ✅ ПРАВИЛЬНО - цепочки методов
result = numbers
  .select(&:even?)
  .map { |n| n * 2 }
  .reduce(0, :+)
```

### flat_map vs map + flatten
```ruby
# ✅ ПРАВИЛЬНО - flat_map для одного уровня
users.flat_map(&:posts)

# ❌ НЕПРАВИЛЬНО
users.map(&:posts).flatten

# Исключение: для глубокой вложенности
nested = [[[1]], [[2]], [[3]]]
nested.map(&:first).flatten  # Если нужно полное выравнивание
```

### Проверки и поиск
```ruby
# ✅ ПРАВИЛЬНО - предикатные методы
arr.any?(&:negative?)
arr.all?(&:positive?)
arr.none?(&:zero?)
arr.one?(&:nil?)
arr.include?(5)

# find для первого совпадения
first_admin = users.find(&:admin?)

# ❌ НЕПРАВИЛЬНО - неэффективно
users.select(&:admin?).first  # используйте find
arr.count > 0  # используйте any?
arr.length == 0  # используйте empty?
```

### reverse_each
```ruby
# ✅ ПРАВИЛЬНО - эффективнее
array.reverse_each { |item| process(item) }

# ❌ НЕПРАВИЛЬНО
array.reverse.each { |item| process(item) }
```

## Хеши

### Создание
```ruby
# ✅ ПРАВИЛЬНО - современный синтаксис для символьных ключей
user = { name: 'John', age: 30, active: true }

# Ruby 3.1+ - сокращенный синтаксис
name = 'John'
age = 30
user = { name:, age:, active: true }

# Смешанные ключи - используйте hash rockets
config = { 'host' => 'localhost', :port => 3000 }

# ❌ НЕПРАВИЛЬНО - смешение стилей
config = { host: 'localhost', 'port' => 3000 }
```

### Доступ к значениям
```ruby
# ✅ ПРАВИЛЬНО - fetch для обязательных ключей
user.fetch(:name)  # выбросит KeyError если нет ключа

# С дефолтным значением
user.fetch(:admin, false)

# С блоком для вычисляемых значений
user.fetch(:permissions) { calculate_permissions }

# ❌ НЕПРАВИЛЬНО для обязательных ключей
user[:name]  # вернет nil если нет ключа
```

### Итерация
```ruby
# ✅ ПРАВИЛЬНО - специализированные методы
hash.each_key { |k| puts k }
hash.each_value { |v| puts v }
hash.each_pair { |k, v| puts "#{k}: #{v}" }

# ❌ НЕПРАВИЛЬНО
hash.keys.each { |k| puts k }
hash.values.each { |v| puts v }
```

### Трансформация
```ruby
# ✅ ПРАВИЛЬНО - transform_keys/values
{ a: 1, b: 2 }.transform_values { |v| v * 2 }
# => { a: 2, b: 4 }

{ a: 1, b: 2 }.transform_keys(&:to_s)
# => { "a" => 1, "b" => 2 }

# Множественный доступ
email, name = user.values_at(:email, :name)
email, name = user.fetch_values(:email, :name)  # с проверкой
```

### Слияние
```ruby
# ✅ ПРАВИЛЬНО
defaults = { color: 'red', size: 'medium' }
options = { size: 'large' }
result = defaults.merge(options)

# Для изменения на месте
defaults.merge!(options)

# С блоком для разрешения конфликтов
h1.merge(h2) { |key, old, new| old + new }
```

### Проверка ключей и значений
```ruby
# ✅ ПРАВИЛЬНО - современные методы
hash.key?(:name)
hash.value?('John')

# ❌ НЕПРАВИЛЬНО - устаревшие методы
hash.has_key?(:name)
hash.has_value?('John')
```

## Set

### Использование для уникальных элементов
```ruby
require 'set'

# ✅ ПРАВИЛЬНО - Set для уникальных значений
unique_ids = Set.new
unique_ids << 1 << 2 << 1  # => #<Set: {1, 2}>

# Из массива
numbers = [1, 2, 2, 3, 3, 3]
unique = numbers.to_set  # => #<Set: {1, 2, 3}>

# Операции множеств
set1 = Set[1, 2, 3]
set2 = Set[2, 3, 4]

set1 & set2  # пересечение => #<Set: {2, 3}>
set1 | set2  # объединение => #<Set: {1, 2, 3, 4}>
set1 - set2  # разность => #<Set: {1}>
```

## Enumerable методы

### Предпочтительные алиасы
```ruby
# ✅ ПРАВИЛЬНО - используйте эти имена
collection.map { |x| x * 2 }
collection.find { |x| x > 10 }
collection.select { |x| x.even? }
collection.reduce(0, :+)
collection.include?(5)
collection.size

# ❌ OK, но менее предпочтительно
collection.collect { |x| x * 2 }
collection.detect { |x| x > 10 }
collection.find_all { |x| x.even? }
collection.inject(0, :+)
collection.member?(5)
collection.length
```

### count vs size
```ruby
# ✅ ПРАВИЛЬНО - size для массивов и хешей
array.size
hash.size

# ❌ НЕПРАВИЛЬНО - count проходит всю коллекцию
some_enumerable.count  # O(n)

# ✅ OK - count с условием
array.count(&:even?)
array.count { |x| x > 10 }
```

### Ленивые вычисления
```ruby
# ✅ ПРАВИЛЬНО - для больших коллекций
(1..Float::INFINITY)
  .lazy
  .select(&:even?)
  .map { |x| x * 2 }
  .first(10)
```

## Блоки и итераторы

### Однострочные vs многострочные
```ruby
# ✅ ПРАВИЛЬНО - {} для однострочных
names.map { |n| n.upcase }

# ✅ ПРАВИЛЬНО - do...end для многострочных
names.each do |name|
  puts name
  process(name)
end

# При цепочке методов - всегда {}
names
  .select { |n| n.length > 3 }
  .map { |n| n.upcase }
```

### Использование &:method_name
```ruby
# ✅ ПРАВИЛЬНО - для простых случаев
numbers.map(&:to_s)
strings.select(&:empty?)
users.find(&:admin?)

# Когда НЕ использовать
# ❌ Когда нужны аргументы
numbers.map { |n| n.round(2) }

# ❌ Когда логика сложнее одного метода
users.select { |u| u.active? && u.admin? }
```

## Object#then (tap, yield_self)

```ruby
# ✅ ПРАВИЛЬНО - then для цепочек трансформаций
result = data
  .then { |d| parse(d) }
  .then { |parsed| validate(parsed) }
  .then { |valid| transform(valid) }

# tap для побочных эффектов
user = User.new(params)
  .tap { |u| u.generate_token }
  .tap { |u| logger.info("User created: #{u.id}") }
```

## Изменение коллекций

### Избегайте изменения во время итерации
```ruby
# ❌ НЕПРАВИЛЬНО - изменение во время итерации
array.each do |item|
  array.delete(item) if item.negative?
end

# ✅ ПРАВИЛЬНО - используйте подходящий метод
array.reject!(&:negative?)
# или
array = array.reject(&:negative?)
```

### Мутабельные операции
```ruby
# Методы с ! изменяют объект на месте
array.map!(&:upcase)    # изменяет array
array.select!(&:valid?) # изменяет array
array.compact!          # удаляет nil

# Без ! - возвращают новый объект
new_array = array.map(&:upcase)
new_array = array.select(&:valid?)
```

## Производительность

### Ранний выход
```ruby
# ✅ ПРАВИЛЬНО - останавливается на первом совпадении
users.any?(&:admin?)
users.find(&:admin?)

# ❌ НЕПРАВИЛЬНО - проходит всю коллекцию
users.map(&:admin?).include?(true)
users.select(&:admin?).first
```

### Предварительное выделение памяти
```ruby
# ✅ ПРАВИЛЬНО - когда знаете размер
result = Array.new(1000)
1000.times { |i| result[i] = process(i) }

# Вместо
result = []
1000.times { |i| result << process(i) }
```

## Рекомендации для Claude Code

1. **Функциональный стиль** - предпочитайте map/select/reduce над императивными циклами
2. **Неизменяемость** - создавайте новые коллекции вместо изменения существующих
3. **Цепочки методов** - используйте для читаемости
4. **Правильный метод** - выбирайте наиболее семантически подходящий метод
5. **Производительность** - учитывайте сложность операций (O(n) vs O(1))
