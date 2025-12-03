# Rails Turbo & Stimulus - Современный фронтенд

## Turbo основы

### Turbo Drive
```html
<!-- Отключение Turbo для конкретных ссылок -->
<%= link_to "Download", download_path, data: { turbo: false } %>

<!-- Отключение Turbo для формы -->
<%= form_with model: @user, data: { turbo: false } do |f| %>
  <!-- форма будет отправлена обычным способом -->
<% end %>

<!-- Принудительная перезагрузка страницы -->
<%= link_to "Settings", settings_path, data: { turbo_action: "replace" } %>

<!-- Prefetch при hover -->
<%= link_to "Profile", profile_path, data: { turbo_prefetch: true } %>
```

### Meta теги для Turbo
```erb
<!-- app/views/layouts/application.html.erb -->
<head>
  <!-- Отключить кеш для страницы -->
  <meta name="turbo-cache-control" content="no-cache">
  
  <!-- Отключить preview при навигации назад -->
  <meta name="turbo-cache-control" content="no-preview">
  
  <!-- Требовать подтверждение при уходе со страницы -->
  <meta name="turbo-visit-control" content="reload">
  
  <!-- Автоматический редирект -->
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
</head>
```

## Turbo Frames

### Базовое использование
```erb
<!-- Определение frame -->
<turbo-frame id="messages">
  <%= render @messages %>
</turbo-frame>

<!-- Ссылка обновляет только frame -->
<%= link_to "Edit", edit_message_path(message), 
    data: { turbo_frame: "messages" } %>

<!-- Форма отправляется в frame -->
<turbo-frame id="new_message">
  <%= form_with model: Message.new do |f| %>
    <%= f.text_field :content %>
    <%= f.submit %>
  <% end %>
</turbo-frame>

<!-- Lazy loading frame -->
<turbo-frame id="comments" src="<%= comments_path %>" loading="lazy">
  <div class="spinner">Loading comments...</div>
</turbo-frame>

<!-- Frame с target -->
<turbo-frame id="message_1" target="_top">
  <!-- Ссылки внутри обновят всю страницу -->
</turbo-frame>
```

### Вложенные frames
```erb
<turbo-frame id="inbox">
  <h2>Inbox</h2>
  
  <turbo-frame id="message_list">
    <% @messages.each do |message| %>
      <turbo-frame id="<%= dom_id(message) %>">
        <%= link_to message.subject, message %>
      </turbo-frame>
    <% end %>
  </turbo-frame>
  
  <turbo-frame id="message_content">
    <!-- Содержимое сообщения загрузится сюда -->
  </turbo-frame>
</turbo-frame>
```

### Frame события
```javascript
// app/javascript/application.js
document.addEventListener("turbo:frame-load", (event) => {
  console.log(`Frame ${event.target.id} loaded`);
});

document.addEventListener("turbo:frame-render", (event) => {
  console.log(`Frame ${event.target.id} rendered`);
});

document.addEventListener("turbo:frame-missing", (event) => {
  event.preventDefault();
  event.detail.visit(event.detail.response);
});
```

## Turbo Streams

### Stream responses
```erb
<!-- app/views/messages/create.turbo_stream.erb -->
<%= turbo_stream.append "messages" do %>
  <%= render partial: "message", locals: { message: @message } %>
<% end %>

<%= turbo_stream.update "messages_count" do %>
  Total: <%= @messages.count %>
<% end %>

<%= turbo_stream.replace dom_id(@message) do %>
  <%= render @message %>
<% end %>

<%= turbo_stream.remove dom_id(@deleted_message) %>

<%= turbo_stream.before "message_1" do %>
  <div class="alert">New message above!</div>
<% end %>

<%= turbo_stream.after "message_1" do %>
  <div class="alert">New message below!</div>
<% end %>
```

### Множественные операции
```erb
<!-- Multiple stream actions -->
<%= turbo_stream.append "messages", @message %>

<%= turbo_stream.update "unread_count" do %>
  <%= current_user.unread_messages_count %>
<% end %>

<%= turbo_stream.replace "flash" do %>
  <%= render "shared/flash" %>
<% end %>
```

### Broadcasting (ActionCable)
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user
  
  # После создания
  after_create_commit -> {
    broadcast_append_to room,
                       target: "messages",
                       partial: "messages/message",
                       locals: { message: self }
  }
  
  # После обновления
  after_update_commit -> {
    broadcast_replace_to room
  }
  
  # После удаления
  after_destroy_commit -> {
    broadcast_remove_to room
  }
  
  # Кастомный broadcast
  after_create_commit :notify_users
  
  private
  
  def notify_users
    broadcast_prepend_to "notifications",
                        target: "notifications_list",
                        partial: "notifications/new_message",
                        locals: { message: self }
  end
end
```

### Подписка на broadcasts
```erb
<!-- app/views/rooms/show.html.erb -->
<%= turbo_stream_from @room %>

<div id="messages">
  <%= render @room.messages %>
</div>

<!-- Подписка на несколько каналов -->
<%= turbo_stream_from @room %>
<%= turbo_stream_from current_user %>
<%= turbo_stream_from "notifications" %>
```

## Stimulus Controllers

### Базовый контроллер
```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "output"]
  static values = { 
    message: String,
    count: { type: Number, default: 0 }
  }
  static classes = ["enabled", "disabled"]
  static outlets = ["user"]
  
  connect() {
    console.log("Hello controller connected")
    this.element.style.backgroundColor = "yellow"
  }
  
  disconnect() {
    console.log("Hello controller disconnected")
  }
  
  greet() {
    const name = this.nameTarget.value
    this.outputTarget.textContent = `Hello, ${name}!`
    this.countValue++
  }
  
  countValueChanged(value, previousValue) {
    console.log(`Count changed from ${previousValue} to ${value}`)
  }
}
```

### HTML интеграция
```erb
<div data-controller="hello"
     data-hello-message-value="Welcome"
     data-hello-count-value="0"
     data-hello-enabled-class="text-green-500"
     data-hello-disabled-class="text-gray-500">
  
  <input data-hello-target="name" type="text">
  
  <button data-action="click->hello#greet">
    Greet
  </button>
  
  <span data-hello-target="output"></span>
</div>
```

### Сложный пример - модальное окно
```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "background"]
  static values = { open: Boolean }
  
  connect() {
    this.element.style.display = this.openValue ? "block" : "none"
  }
  
  open(event) {
    event.preventDefault()
    this.openValue = true
  }
  
  close(event) {
    if (event.detail.success) {
      this.openValue = false
    }
  }
  
  closeBackground(event) {
    if (event.target === this.backgroundTarget) {
      this.openValue = false
    }
  }
  
  closeWithKeyboard(event) {
    if (event.keyCode === 27) {
      this.openValue = false
    }
  }
  
  openValueChanged() {
    if (this.openValue) {
      this.showModal()
    } else {
      this.hideModal()
    }
  }
  
  showModal() {
    this.element.style.display = "block"
    document.body.classList.add("modal-open")
    this.lockScroll()
  }
  
  hideModal() {
    this.element.style.display = "none"
    document.body.classList.remove("modal-open")
    this.unlockScroll()
  }
  
  lockScroll() {
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth
    document.body.style.paddingRight = `${scrollbarWidth}px`
    document.body.style.overflow = "hidden"
  }
  
  unlockScroll() {
    document.body.style.paddingRight = ""
    document.body.style.overflow = ""
  }
}
```

### Form контроллер с валидацией
```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "errors"]
  static values = { url: String }
  
  connect() {
    this.validateForm()
  }
  
  async submit(event) {
    event.preventDefault()
    
    const formData = new FormData(this.element)
    
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken
        },
        body: formData
      })
      
      if (response.ok) {
        Turbo.visit(response.headers.get("Location"))
      } else {
        const errors = await response.json()
        this.showErrors(errors)
      }
    } catch (error) {
      console.error("Form submission error:", error)
    }
  }
  
  validateForm() {
    const isValid = this.element.checkValidity()
    this.submitTarget.disabled = !isValid
  }
  
  showErrors(errors) {
    this.errorsTarget.innerHTML = errors.map(error => 
      `<div class="error">${error}</div>`
    ).join("")
  }
  
  clearErrors() {
    this.errorsTarget.innerHTML = ""
  }
  
  get csrfToken() {
    return document.querySelector("[name='csrf-token']").content
  }
}
```

## Stimulus + Turbo интеграция

### Автосохранение формы
```javascript
// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = { 
    url: String, 
    delay: { type: Number, default: 1000 }
  }
  static targets = ["status"]
  
  connect() {
    this.timeout = null
  }
  
  disconnect() {
    this.save()
  }
  
  change() {
    clearTimeout(this.timeout)
    this.statusTarget.textContent = "Изменено..."
    
    this.timeout = setTimeout(() => {
      this.save()
    }, this.delayValue)
  }
  
  async save() {
    const formData = new FormData(this.element)
    
    this.statusTarget.textContent = "Сохранение..."
    
    const response = await patch(this.urlValue, {
      body: formData,
      responseKind: "turbo-stream"
    })
    
    if (response.ok) {
      this.statusTarget.textContent = "Сохранено"
      setTimeout(() => {
        this.statusTarget.textContent = ""
      }, 2000)
    }
  }
}
```

### Infinite scroll
```javascript
// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, page: Number }
  static targets = ["entries", "loader"]
  
  connect() {
    this.createObserver()
  }
  
  disconnect() {
    this.observer.disconnect()
  }
  
  createObserver() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersection(entries),
      { threshold: 0.5 }
    )
    
    if (this.hasLoaderTarget) {
      this.observer.observe(this.loaderTarget)
    }
  }
  
  async handleIntersection(entries) {
    const entry = entries[0]
    
    if (entry.isIntersecting && this.hasMorePages) {
      await this.loadMore()
    }
  }
  
  async loadMore() {
    this.loading = true
    this.pageValue++
    
    const response = await fetch(`${this.urlValue}?page=${this.pageValue}`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    
    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    } else {
      this.hasMorePages = false
      this.loaderTarget.remove()
    }
    
    this.loading = false
  }
  
  get hasMorePages() {
    return !this.loading && this.hasLoaderTarget
  }
}
```

## Request.js интеграция

```javascript
// app/javascript/controllers/request_controller.js
import { Controller } from "@hotwired/stimulus"
import { get, post, patch, destroy } from "@rails/request.js"

export default class extends Controller {
  async loadData() {
    const response = await get("/api/data", {
      query: { filter: "active" },
      responseKind: "json"
    })
    
    if (response.ok) {
      const data = await response.json
      this.updateView(data)
    }
  }
  
  async saveData(event) {
    event.preventDefault()
    
    const response = await post("/api/data", {
      body: JSON.stringify({ name: "Test" }),
      contentType: "application/json",
      responseKind: "turbo-stream"
    })
    
    if (!response.ok) {
      const error = await response.text
      console.error(error)
    }
  }
  
  async deleteItem(event) {
    const id = event.currentTarget.dataset.id
    
    if (confirm("Are you sure?")) {
      const response = await destroy(`/api/items/${id}`, {
        responseKind: "turbo-stream"
      })
      
      if (response.ok) {
        event.currentTarget.closest(".item").remove()
      }
    }
  }
}
```

## Importmaps конфигурация

```ruby
# config/importmap.rb
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Контроллеры
pin_all_from "app/javascript/controllers", under: "controllers"

# Дополнительные библиотеки
pin "debounce", to: "https://ga.jspm.io/npm:debounce@1.2.1/index.js"
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.0/modular/sortable.esm.js"

# Локальные модули
pin_all_from "app/javascript/helpers", under: "helpers"
pin_all_from "app/javascript/channels", under: "channels"
```

## Best Practices

### Организация Stimulus контроллеров
```javascript
// app/javascript/controllers/concerns/debounced.js
export default function debounced(delay = 300) {
  return function(target, key, descriptor) {
    let timeout = null
    const original = descriptor.value
    
    descriptor.value = function(...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => {
        original.apply(this, args)
      }, delay)
    }
    
    return descriptor
  }
}

// Использование
import debounced from "./concerns/debounced"

export default class extends Controller {
  @debounced(500)
  search() {
    // Вызывается с задержкой 500ms
  }
}
```

### Композиция контроллеров
```erb
<div data-controller="dropdown toggle visibility"
     data-dropdown-url-value="<%= api_path %>"
     data-visibility-hidden-class="hidden">
  <!-- Несколько контроллеров на одном элементе -->
</div>
```

## Рекомендации для Claude Code

1. **Turbo по умолчанию** - для SPA-like опыта без сложности
2. **Минимум JavaScript** - используйте Stimulus для интерактивности
3. **Server-side rendering** - основная логика на сервере
4. **Progressive enhancement** - сайт работает без JS
5. **Маленькие контроллеры** - один контроллер = одна ответственность
6. **Data attributes** - для конфигурации и состояния
7. **Turbo Streams для real-time** - вместо сложных WebSocket решений
