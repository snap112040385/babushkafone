# Ruby Exceptions - Обработка исключений

## Основные принципы

### raise vs fail
```ruby
# ✅ ПРАВИЛЬНО - используйте raise
raise ArgumentError, 'Invalid argument'

# ❌ НЕПРАВИЛЬНО - fail устарел
fail ArgumentError, 'Invalid argument'
```

### Создание исключений
```ruby
# ✅ ПРАВИЛЬНО - класс и сообщение отдельно
raise ArgumentError, 'Name cannot be blank'
raise CustomError, 'Something went wrong', backtrace

# ❌ НЕПРАВИЛЬНО - создание экземпляра
raise ArgumentError.new('Name cannot be blank')
```

### RuntimeError по умолчанию
```ruby
# ✅ ПРАВИЛЬНО - RuntimeError подразумевается
raise 'Something went wrong'

# ❌ НЕПРАВИЛЬНО - явное указание RuntimeError
raise RuntimeError, 'Something went wrong'
```

## Обработка исключений

### begin/rescue/ensure/else
```ruby
# ✅ ПРАВИЛЬНО - полная структура
begin
  # опасный код
  result = risky_operation
rescue ArgumentError => e
  # обработка ArgumentError
  log_error(e)
  default_value
rescue StandardError => e
  # обработка других стандартных ошибок
  handle_error(e)
else
  # выполняется если не было исключений
  log_success(result)
ensure
  # выполняется всегда
  cleanup_resources
end
```

### Неявные begin блоки
```ruby
# ✅ ПРАВИЛЬНО - в методах begin не нужен
def process_data
  dangerous_operation
rescue StandardError => e
  log_error(e)
  nil
end

# ❌ НЕПРАВИЛЬНО - избыточный begin
def process_data
  begin
    dangerous_operation
  rescue StandardError => e
    log_error(e)
    nil
  end
end
```

### Порядок rescue
```ruby
# ✅ ПРАВИЛЬНО - от специфичных к общим
begin
  http_request
rescue Net::ReadTimeout => e
  retry_request
rescue Net::HTTPError => e
  log_http_error(e)
rescue StandardError => e
  log_general_error(e)
end

# ❌ НЕПРАВИЛЬНО - общие первыми
begin
  http_request
rescue StandardError => e  # поймает все!
  log_general_error(e)
rescue Net::HTTPError => e  # никогда не выполнится
  log_http_error(e)
end
```

## Кастомные исключения

### Определение
```ruby
# ✅ ПРАВИЛЬНО - наследование от StandardError
class ApplicationError < StandardError; end

class ValidationError < ApplicationError
  attr_reader :field
  
  def initialize(field, message = nil)
    @field = field
    super(message || "Validation failed for #{field}")
  end
end

class NotFoundError < ApplicationError
  def initialize(resource_type, id)
    super("#{resource_type} with id #{id} not found")
  end
end
```

### Иерархия исключений
```ruby
# ✅ ПРАВИЛЬНО - логичная иерархия
module MyApp
  class Error < StandardError; end
  
  # Группы ошибок
  class ValidationError < Error; end
  class AuthenticationError < Error; end
  class AuthorizationError < Error; end
  
  # Специфичные ошибки
  class InvalidEmailError < ValidationError; end
  class TokenExpiredError < AuthenticationError; end
  class InsufficientPermissionsError < AuthorizationError; end
end
```

## Антипаттерны

### Не скрывайте исключения
```ruby
# ❌ НЕПРАВИЛЬНО - тихое проглатывание
begin
  dangerous_operation
rescue StandardError
  # ничего не делаем - плохо!
end

# ✅ ПРАВИЛЬНО - хотя бы логирование
begin
  dangerous_operation
rescue StandardError => e
  Rails.logger.error "Operation failed: #{e.message}"
  # можно также re-raise или вернуть безопасное значение
end
```

### Не используйте исключения для control flow
```ruby
# ❌ НЕПРАВИЛЬНО - исключения для логики
def find_user(id)
  raise NotFoundError unless user = User.find_by(id: id)
  user
end

begin
  user = find_user(params[:id])
rescue NotFoundError
  redirect_to users_path
end

# ✅ ПРАВИЛЬНО - явная проверка
def find_user(id)
  User.find_by(id: id)
end

if user = find_user(params[:id])
  # работаем с user
else
  redirect_to users_path
end
```

### Не перехватывайте Exception
```ruby
# ❌ НЕПРАВИЛЬНО - ловит системные сигналы!
begin
  dangerous_code
rescue Exception => e
  # Поймает даже Ctrl+C (SignalException)
end

# ✅ ПРАВИЛЬНО - ловите StandardError
begin
  dangerous_code
rescue StandardError => e
  handle_error(e)
end

# или просто rescue (по умолчанию StandardError)
begin
  dangerous_code
rescue => e
  handle_error(e)
end
```

### Не используйте rescue модификатор
```ruby
# ❌ НЕПРАВИЛЬНО - скрывает все ошибки
value = dangerous_method rescue nil

# ✅ ПРАВИЛЬНО - явная обработка
value = begin
  dangerous_method
rescue SpecificError => e
  log_error(e)
  nil
end

# или в методе
def safe_method
  dangerous_method
rescue SpecificError => e
  log_error(e)
  nil
end
```

## return в ensure

```ruby
# ❌ НЕПРАВИЛЬНО - return в ensure перезаписывает исключение
def dangerous_method
  raise 'Error!'
ensure
  return 'Always returns this'  # Исключение потеряно!
end

# ✅ ПРАВИЛЬНО
def dangerous_method
  raise 'Error!'
ensure
  cleanup  # только очистка, без return
end
```

## Повторные попытки (retry)

```ruby
# ✅ ПРАВИЛЬНО - ограниченное количество попыток
retries = 0
begin
  api_call
rescue Net::ReadTimeout => e
  retries += 1
  if retries < 3
    sleep(2 ** retries)  # экспоненциальная задержка
    retry
  else
    raise
  end
end
```

## Специальные методы

### Использование tap для обработки ошибок
```ruby
# ✅ Удобно для цепочек
def create_user(params)
  User.new(params)
    .tap(&:validate!)
    .tap(&:save!)
rescue ActiveRecord::RecordInvalid => e
  log_validation_error(e)
  nil
end
```

### Contingency методы (Avdi Grimm pattern)
```ruby
# ✅ ПРАВИЛЬНО - изоляция обработки ошибок
def with_error_handling
  yield
rescue NetworkError => e
  log_network_error(e)
  retry_later
rescue ValidationError => e
  log_validation_error(e)
  show_errors_to_user(e)
end

# Использование
with_error_handling do
  process_payment(order)
end

with_error_handling do
  send_notification(user)
end
```

## Стандартные исключения Ruby

### Иерархия исключений
```
Exception
├── NoMemoryError
├── ScriptError
│   ├── LoadError
│   ├── NotImplementedError
│   └── SyntaxError
├── SecurityError
├── SignalException
│   └── Interrupt
├── StandardError (ловите эти!)
│   ├── ArgumentError
│   ├── EncodingError
│   ├── FiberError
│   ├── IOError
│   │   └── EOFError
│   ├── IndexError
│   │   ├── KeyError
│   │   └── StopIteration
│   ├── LocalJumpError
│   ├── NameError
│   │   └── NoMethodError
│   ├── RangeError
│   │   └── FloatDomainError
│   ├── RegexpError
│   ├── RuntimeError (default для raise)
│   ├── SystemCallError
│   │   └── Errno::*
│   ├── ThreadError
│   ├── TypeError
│   └── ZeroDivisionError
├── SystemExit
└── SystemStackError
```

## Best Practices

### Документирование исключений
```ruby
# @raise [ArgumentError] если имя пустое
# @raise [DuplicateError] если пользователь с таким email существует
def create_user!(name:, email:)
  raise ArgumentError, 'Name is required' if name.blank?
  raise DuplicateError, 'Email already taken' if User.exists?(email: email)
  
  User.create!(name: name, email: email)
end
```

### Логирование исключений
```ruby
# ✅ Структурированное логирование
begin
  process_order(order)
rescue => e
  logger.error({
    message: 'Order processing failed',
    error_class: e.class.name,
    error_message: e.message,
    backtrace: e.backtrace.first(5),
    order_id: order.id
  }.to_json)
  
  # Re-raise если критично
  raise if critical_error?(e)
  
  # Или вернуть дефолт
  default_order_result
end
```

### Обертки для внешних сервисов
```ruby
class PaymentGateway
  class PaymentError < StandardError; end
  class InvalidCardError < PaymentError; end
  class InsufficientFundsError < PaymentError; end
  
  def charge(amount, card)
    response = external_api.charge(amount, card)
    handle_response(response)
  rescue ExternalAPI::Error => e
    # Преобразуем внешние исключения в наши
    case e.code
    when 'invalid_card'
      raise InvalidCardError, e.message
    when 'insufficient_funds'
      raise InsufficientFundsError, e.message
    else
      raise PaymentError, "Payment failed: #{e.message}"
    end
  end
end
```

## Рекомендации для Claude Code

1. **Всегда наследуйтесь от StandardError** для кастомных исключений
2. **Обрабатывайте исключения явно** - не используйте rescue без класса
3. **Логируйте исключения** - для отладки в production
4. **Не используйте исключения для логики** - они для исключительных ситуаций
5. **Создавайте иерархии исключений** - для гибкой обработки
6. **Документируйте исключения** - какие исключения может выбросить метод
