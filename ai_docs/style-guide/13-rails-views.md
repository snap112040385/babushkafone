# Rails Views - Представления и шаблоны

## Структура views

### Организация файлов
```
app/views/
├── layouts/
│   ├── application.html.erb
│   ├── admin.html.erb
│   └── mailer.html.erb
├── shared/
│   ├── _header.html.erb
│   ├── _footer.html.erb
│   └── _flash.html.erb
├── users/
│   ├── index.html.erb
│   ├── show.html.erb
│   ├── _form.html.erb
│   └── _user.html.erb
└── application/
    └── home.html.erb
```

## ERB шаблоны

### Базовый синтаксис
```erb
<%# Комментарий - не попадет в HTML %>

<% # Ruby код без вывода %>
<% @users.each do |user| %>
  
<%= # Ruby код с выводом (escaped) %>
<%= user.name %>

<%== # Ruby код с выводом (raw - без экранирования) %>
<%== user.bio_html %>

<%- # Ruby код без вывода и без пустых строк -%>
<%- if user.admin? -%>
  Admin
<%- end -%>
```

### Безопасность вывода
```erb
<!-- ✅ ПРАВИЛЬНО - автоматическое экранирование -->
<%= user.name %>
<%= link_to user.name, user_path(user) %>

<!-- ❌ ОПАСНО - без экранирования -->
<%== user.input %>
<%= raw(user.input) %>
<%= user.input.html_safe %>

<!-- ✅ Безопасный raw вывод -->
<%= sanitize(user.bio, tags: %w[p br strong em]) %>
<%= simple_format(user.description) %>
```

## Layouts

### application.html.erb
```erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <title><%= content_for(:title) || "MyApp" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="turbo-cache-control" content="no-cache">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    
    <!-- Rails 8 с Propshaft -->
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
    
    <!-- Import maps -->
    <%= javascript_importmap_tags %>
    
    <!-- PWA -->
    <link rel="manifest" href="/manifest.json">
    
    <%= yield :head %>
  </head>

  <body class="<%= controller_name %> <%= action_name %>">
    <%= render "shared/header" %>
    
    <main class="container">
      <%= render "shared/flash" %>
      <%= yield %>
    </main>
    
    <%= render "shared/footer" %>
    <%= yield :scripts %>
  </body>
</html>
```

### content_for и yield
```erb
<!-- В view -->
<% content_for :title, "Профиль пользователя" %>
<% content_for :meta do %>
  <meta property="og:title" content="<%= @user.name %>">
  <meta property="og:image" content="<%= @user.avatar_url %>">
<% end %>

<% content_for :sidebar do %>
  <%= render "users/sidebar", user: @user %>
<% end %>

<!-- В layout -->
<title><%= yield(:title) %></title>
<%= yield(:meta) %>

<div class="sidebar">
  <%= yield(:sidebar) || render("shared/default_sidebar") %>
</div>
```

## Partials

### Именование и использование
```erb
<!-- Partial: app/views/users/_user.html.erb -->
<div class="user" id="<%= dom_id(user) %>">
  <%= image_tag user.avatar, class: "avatar" %>
  <h3><%= link_to user.name, user %></h3>
  <p><%= user.bio %></p>
</div>

<!-- Использование -->
<%= render "users/user", user: @user %>
<%= render partial: "users/user", locals: { user: @user } %>

<!-- Коллекции -->
<%= render @users %>
<%= render partial: "user", collection: @users %>

<!-- С layout для partial -->
<%= render partial: "user", collection: @users, 
           layout: "layouts/card" %>

<!-- С spacer template -->
<%= render partial: "user", collection: @users,
           spacer_template: "shared/divider" %>
```

### Передача переменных
```erb
<!-- ✅ ПРАВИЛЬНО - явная передача -->
<%= render "form", user: @user, method: :patch %>

<!-- ❌ НЕПРАВИЛЬНО - использование instance переменных -->
<!-- В partial не используйте @user напрямую -->
<%= render "form" %>  <!-- и внутри обращение к @user -->

<!-- Проверка наличия переменной в partial -->
<% if local_assigns[:show_avatar] %>
  <%= image_tag user.avatar %>
<% end %>
```

## Helpers

### Application Helper
```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def page_title(title = nil)
    base_title = "MyApp"
    title.present? ? "#{title} | #{base_title}" : base_title
  end
  
  def flash_class(level)
    case level.to_sym
    when :notice then "alert alert-info"
    when :success then "alert alert-success"
    when :error, :alert then "alert alert-danger"
    when :warning then "alert alert-warning"
    else "alert alert-info"
    end
  end
  
  def active_link_to(name, path, **options)
    css_class = current_page?(path) ? "active" : ""
    options[:class] = [options[:class], css_class].compact.join(" ")
    link_to name, path, options
  end
  
  def markdown(text)
    return "" if text.blank?
    
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      hard_wrap: true
    )
    markdown = Redcarpet::Markdown.new(renderer, 
      autolink: true,
      tables: true
    )
    
    sanitize(markdown.render(text))
  end
end
```

### Специфичные helpers
```ruby
# app/helpers/users_helper.rb
module UsersHelper
  def avatar_for(user, size: 100, css_class: "avatar")
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [size, size]),
                class: css_class,
                alt: user.name
    else
      image_tag "default_avatar.png",
                class: css_class,
                size: "#{size}x#{size}",
                alt: user.name
    end
  end
  
  def user_status_badge(user)
    status_class = case user.status
                   when "active" then "success"
                   when "pending" then "warning"
                   when "suspended" then "danger"
                   else "secondary"
                   end
    
    content_tag :span, user.status.humanize, 
                class: "badge bg-#{status_class}"
  end
end
```

## Формы

### form_with (Rails 5.1+)
```erb
<%= form_with model: @user, local: false do |form| %>
  <% if @user.errors.any? %>
    <div class="alert alert-danger">
      <h4><%= pluralize(@user.errors.count, "error") %></h4>
      <ul>
        <% @user.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  
  <div class="form-group">
    <%= form.label :email %>
    <%= form.email_field :email, 
        class: "form-control",
        required: true,
        autocomplete: "email" %>
    <%= form.error :email, class: "invalid-feedback" %>
  </div>
  
  <div class="form-group">
    <%= form.label :password %>
    <%= form.password_field :password,
        class: "form-control",
        autocomplete: "new-password" %>
  </div>
  
  <div class="form-check">
    <%= form.check_box :remember_me, class: "form-check-input" %>
    <%= form.label :remember_me, class: "form-check-label" %>
  </div>
  
  <%= form.submit class: "btn btn-primary" %>
<% end %>
```

### Вложенные формы
```erb
<%= form_with model: @project do |form| %>
  <h3>Задачи</h3>
  
  <div id="tasks">
    <%= form.fields_for :tasks do |task_form| %>
      <%= render "task_fields", form: task_form %>
    <% end %>
  </div>
  
  <%= link_to "Добавить задачу", "#", 
      data: { action: "click->nested-form#add" },
      class: "btn btn-sm btn-secondary" %>
<% end %>

<!-- _task_fields.html.erb -->
<div class="task-fields">
  <%= form.text_field :name, placeholder: "Название задачи" %>
  <%= form.hidden_field :_destroy %>
  <%= link_to "Удалить", "#",
      data: { action: "click->nested-form#remove" } %>
</div>
```

## Turbo Frame и Turbo Stream

### Turbo Frame
```erb
<!-- Layout с turbo frame -->
<turbo-frame id="modal">
  <!-- Контент загружается сюда -->
</turbo-frame>

<!-- Ссылка открывает в frame -->
<%= link_to "Edit", edit_user_path(user), 
    data: { turbo_frame: "modal" } %>

<!-- View с turbo frame -->
<turbo-frame id="user_<%= @user.id %>">
  <h2><%= @user.name %></h2>
  <%= link_to "Edit", edit_user_path(@user) %>
</turbo-frame>

<!-- Form в turbo frame -->
<turbo-frame id="user_<%= @user.id %>">
  <%= form_with model: @user do |form| %>
    <!-- форма -->
  <% end %>
</turbo-frame>
```

### Turbo Stream
```erb
<!-- app/views/messages/create.turbo_stream.erb -->
<%= turbo_stream.append "messages" do %>
  <%= render @message %>
<% end %>

<%= turbo_stream.update "message-count" do %>
  <%= @messages.count %> сообщений
<% end %>

<%= turbo_stream.remove dom_id(@deleted_message) %>

<%= turbo_stream.replace "flash" do %>
  <%= render "shared/flash" %>
<% end %>

<!-- Множественные операции -->
<%= turbo_stream.append "messages", @message %>
<%= turbo_stream.update "unread-count", @unread_count %>
<%= turbo_stream.replace_all ".timestamp", 
    partial: "shared/timestamp" %>
```

## Stimulus интеграция

### Data attributes
```erb
<div data-controller="dropdown">
  <button data-action="click->dropdown#toggle">
    Меню
  </button>
  
  <div data-dropdown-target="menu" class="hidden">
    <!-- Пункты меню -->
  </div>
</div>

<!-- С параметрами -->
<div data-controller="autosave"
     data-autosave-url-value="<%= autosave_path %>"
     data-autosave-interval-value="5000">
  <textarea data-autosave-target="input"
            data-action="input->autosave#reset">
  </textarea>
</div>

<!-- Множественные контроллеры -->
<div data-controller="tooltip dropdown"
     data-tooltip-text-value="Подсказка"
     data-action="mouseenter->tooltip#show 
                  mouseleave->tooltip#hide
                  click->dropdown#toggle">
  Элемент
</div>
```

## Интернационализация

### I18n в views
```erb
<!-- Простой перевод -->
<h1><%= t('users.index.title') %></h1>
<p><%= t('.description') %></p>  <!-- Относительный ключ -->

<!-- С интерполяцией -->
<%= t('users.welcome', name: @user.name) %>

<!-- Плюрализация -->
<%= t('users.messages', count: @messages.count) %>

<!-- HTML-safe переводы -->
<%= t('terms.content_html') %>  <!-- _html суффикс -->

<!-- С default значением -->
<%= t('users.role', default: 'User') %>

<!-- Lazy lookup для views -->
<!-- app/views/users/show.html.erb -->
<%= t('.title') %>  <!-- users.show.title -->
```

### Локализованные partials
```erb
<!-- app/views/users/_form.ru.html.erb -->
<!-- app/views/users/_form.en.html.erb -->

<%= render "form" %>  <!-- Выберет правильную локаль -->
```

## View Components (опционально)

```ruby
# app/components/user_card_component.rb
class UserCardComponent < ViewComponent::Base
  def initialize(user:, show_actions: true)
    @user = user
    @show_actions = show_actions
  end
  
  private
  
  attr_reader :user, :show_actions
end
```

```erb
<!-- app/components/user_card_component.html.erb -->
<div class="user-card" id="<%= dom_id(user) %>">
  <%= avatar_for(user) %>
  <h3><%= link_to user.name, user %></h3>
  
  <% if show_actions %>
    <div class="actions">
      <%= link_to "Edit", edit_user_path(user), 
          class: "btn btn-sm btn-primary" %>
    </div>
  <% end %>
</div>

<!-- Использование -->
<%= render UserCardComponent.new(user: @user) %>
```

## Производительность

### Fragment caching
```erb
<% cache @user do %>
  <div class="user-profile">
    <%= render "users/profile", user: @user %>
  </div>
<% end %>

<!-- С версионированием -->
<% cache ["v2", @user, current_user.admin?] do %>
  <!-- Кешируемый контент -->
<% end %>

<!-- Russian doll caching -->
<% cache @post do %>
  <h1><%= @post.title %></h1>
  
  <% @post.comments.each do |comment| %>
    <% cache comment do %>
      <%= render comment %>
    <% end %>
  <% end %>
<% end %>
```

### Lazy loading
```erb
<!-- Turbo lazy loading -->
<turbo-frame id="comments" src="<%= comments_path %>" loading="lazy">
  <p>Загрузка комментариев...</p>
</turbo-frame>
```

## Рекомендации для Claude Code

1. **Избегайте логики во views** - используйте helpers и presenters
2. **Используйте partials** - для переиспользования кода
3. **Безопасность первична** - всегда экранируйте вывод
4. **Semantic HTML** - используйте правильные теги
5. **Turbo по умолчанию** - для SPA-подобного опыта без JS
