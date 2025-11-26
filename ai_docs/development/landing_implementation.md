# Лендинг - Техническая реализация

## Обзор

Лендинг является главной точкой входа в приложение Babushkafone, выполняя функции маркетинговой и конверсионной страницы для VoIP-сервиса.

## Технологический стек

- **Фреймворк**: Rails 8.1
- **Стилизация**: TailwindCSS 4 (через gem tailwindcss-rails)
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Ассеты**: Propshaft + Importmap

## Архитектура

### Маршруты

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "landing/index"
  get "landing/sasha"
  root "landing#index"
end
```

- **Корневой путь** (`/`): Основной лендинг
- **`/landing/index`**: Прямой доступ к лендингу
- **`/landing/sasha`**: Альтернативная/тестовая версия лендинга

### Контроллер

**Файл**: `/app/controllers/landing_controller.rb`

```ruby
class LandingController < ApplicationController
  def index
  end

  def sasha
  end
end
```

Простой контроллер без бизнес-логики - представления содержат статический маркетинговый контент.

### Представления

**Макет**: `/app/views/layouts/application.html.erb`
- HTML lang установлен на русский (`ru`)
- Мета-теги для SEO и PWA
- Загрузка Google Fonts (Inter)
- Импорты стилей и JavaScript

**Основное представление**: `/app/views/landing/index.html.erb`
- Однофайловый лендинг (~679 строк)
- Все секции в одном ERB-файле
- Используются утилитарные классы TailwindCSS
- Inline SVG-иконки повсюду
- Динамический год в футере: `<%= Date.current.year %>`

## Структура файлов

```
app/
  controllers/
    landing_controller.rb
  views/
    layouts/
      application.html.erb
    landing/
      index.html.erb        # Основной лендинг
      sasha.html.erb        # Альтернативный лендинг
```

## Реализация стилей

### Конфигурация TailwindCSS

Проект использует TailwindCSS 4 через gem `tailwindcss-rails`. Стили обрабатываются во время разработки через `bin/dev`.

### Основные CSS-паттерны

1. **Градиенты**
   - Фон: `bg-gradient-to-br from-indigo-900 via-purple-900 to-indigo-800`
   - Текст: `text-transparent bg-clip-text bg-gradient-to-r from-amber-300 to-orange-400`
   - Кнопки: `bg-gradient-to-r from-amber-400 to-orange-500`

2. **Glassmorphism (стекломорфизм)**
   - `bg-white/10 backdrop-blur`
   - `bg-white/10 backdrop-blur-xl border border-white/20`

3. **Тени**
   - Стандартные: `shadow-sm`, `shadow-lg`, `shadow-xl`, `shadow-2xl`
   - Цветные: `shadow-indigo-900/30`, `shadow-orange-500/30`

4. **Адаптивная сетка**
   - `grid md:grid-cols-2 lg:grid-cols-3`
   - `grid md:grid-cols-3 gap-8`

### Inline SVG-иконки

Все иконки - inline SVG с параметрами:
- `fill="none"` или `fill="currentColor"`
- `stroke="currentColor"`
- `stroke-width="2"`
- `stroke-linecap="round"`
- `stroke-linejoin="round"`

## JavaScript/Stimulus

На данный момент Stimulus-контроллеры на лендинге не используются. Вся интерактивность реализована на CSS:
- Hover-эффекты через псевдокласс `:hover`
- Аккордеон FAQ через нативные элементы `<details>`/`<summary>`
- Мобильное меню (ссылки скрыты через `hidden md:flex`)

## Соображения по производительности

### Текущая реализация
- Весь контент - статический HTML
- Нет запросов к базе данных
- Google Fonts загружаются с `font-display: swap`
- Изображения: только favicon и PWA-иконки (нет контентных изображений)

### Потенциальные оптимизации
1. Рассмотреть ленивую загрузку секций ниже первого экрана
2. Предзагрузка критических начертаний шрифтов
3. Рассмотреть извлечение SVG-иконок в спрайт
4. Добавить графические ассеты для мокапа в hero-секции

## Безопасность

- CSRF мета-теги включены: `<%= csrf_meta_tags %>`
- CSP мета-тег включен: `<%= csp_meta_tag %>`

## Поддержка PWA

PWA-манифест подготовлен, но закомментирован:
```erb
<%#= tag.link rel: "manifest", href: pwa_manifest_path(format: :json) %>
```

Файлы доступны в `/app/views/pwa/`:
- `manifest.json.erb`
- `service-worker.js`

## Тестирование

Расположение тестового файла: `test/controllers/landing_controller_test.rb`

Запуск тестов:
```bash
bin/rails test test/controllers/landing_controller_test.rb
```

## Разработка

Запуск сервера разработки:
```bash
bin/dev
```

Это запускает Rails-сервер + TailwindCSS watcher одновременно.

## Зависимости

Ключевые гемы для лендинга:
- `tailwindcss-rails` - интеграция TailwindCSS
- `propshaft` - пайплайн ассетов
- `importmap-rails` - JavaScript-модули
- `turbo-rails` - Hotwire Turbo
- `stimulus-rails` - Hotwire Stimulus

## Планы на будущее

1. **A/B тестирование**: Добавить поддержку вариантов для тестирования разных заголовков/CTA
2. **Аналитика**: Интегрировать отслеживание событий для кликов по CTA
3. **Локализация**: Рассмотреть i18n для мультиязычной поддержки
4. **Компоненты**: Извлечь переиспользуемые компоненты (кнопки, карточки) в partials
5. **Анимации**: Добавить анимации по скроллу с помощью Stimulus
6. **Формы**: Реализовать сбор email для лидогенерации
