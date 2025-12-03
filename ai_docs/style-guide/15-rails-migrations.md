# Rails Migrations - Миграции базы данных

## Основы миграций

### Создание миграций
```bash
# Создание таблицы
rails generate migration CreateUsers name:string email:string:uniq

# Добавление колонок
rails generate migration AddAgeToUsers age:integer

# Удаление колонок
rails generate migration RemovePhoneFromUsers phone:string

# Добавление индекса
rails generate migration AddIndexToUsersEmail

# Добавление foreign key
rails generate migration AddUserRefToPosts user:references
```

### Структура миграции
```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.integer :age
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end
    
    add_index :users, :email, unique: true
  end
end
```

## Создание таблиц

### create_table
```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      # Основные типы
      t.string :name, null: false, limit: 100
      t.text :description
      t.integer :quantity, default: 0
      t.decimal :price, precision: 10, scale: 2
      t.boolean :available, default: true
      t.date :release_date
      t.datetime :published_at
      t.time :opening_time
      
      # JSON (PostgreSQL)
      t.json :metadata
      t.jsonb :settings, default: {}
      
      # Массивы (PostgreSQL)
      t.string :tags, array: true, default: []
      
      # UUID (PostgreSQL)
      t.uuid :uuid, default: -> { "gen_random_uuid()" }
      
      # Перечисления
      t.integer :status, default: 0, null: false
      
      # Foreign keys
      t.references :user, null: false, foreign_key: true
      t.belongs_to :category, index: true
      
      # Полиморфные связи
      t.references :commentable, polymorphic: true
      
      # Timestamps
      t.timestamps
      # или отдельно
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      
      # Soft delete
      t.datetime :deleted_at
      
      # Дополнительные timestamps
      t.datetime :approved_at
      t.datetime :published_at
    end
    
    # Индексы
    add_index :products, :name
    add_index :products, [:category_id, :available]
    add_index :products, :deleted_at
    
    # Составной уникальный индекс
    add_index :products, [:user_id, :name], unique: true
    
    # Частичный индекс (PostgreSQL)
    add_index :products, :status, where: "deleted_at IS NULL"
  end
end
```

### Опции для create_table
```ruby
create_table :users, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
  # для MySQL
end

create_table :users, id: :uuid do |t|
  # UUID как primary key (PostgreSQL)
end

create_table :users, id: false do |t|
  # Без primary key
  t.string :custom_id, primary_key: true
end

create_table :users, temporary: true do |t|
  # Временная таблица
end

create_table :users, if_not_exists: true do |t|
  # Создать только если не существует
end
```

## Изменение таблиц

### Добавление колонок
```ruby
class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :birth_date, :date
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :balance, :decimal, precision: 10, scale: 2, default: 0
    
    # С индексом
    add_column :users, :username, :string
    add_index :users, :username, unique: true
    
    # Reference
    add_reference :users, :company, foreign_key: true
    
    # Timestamps
    add_timestamps :users, default: DateTime.now
  end
end
```

### Изменение колонок
```ruby
class ChangeUsersTable < ActiveRecord::Migration[8.0]
  def change
    # Переименование
    rename_column :users, :email, :email_address
    
    # Изменение типа (необратимо!)
    change_column :users, :age, :string
    
    # Изменение default
    change_column_default :users, :active, from: true, to: false
    
    # Изменение null constraint
    change_column_null :users, :email, false
    
    # Добавление комментария
    change_column_comment :users, :encrypted_password, 
                          "Хеш пароля, зашифрованный bcrypt"
    
    change_table :users do |t|
      t.rename :email, :email_address
      t.string :phone
      t.remove :age
      t.index :phone
    end
  end
end
```

### Удаление колонок (безопасно)
```ruby
class RemovePhoneFromUsers < ActiveRecord::Migration[8.0]
  def change
    # Безопасное удаление с обратимостью
    remove_column :users, :phone, :string
  end
end

# Для production - используйте safety_assured
class RemoveLargeColumn < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :users, :huge_data }
  end
end
```

## Индексы

### Управление индексами
```ruby
class AddIndexesToUsers < ActiveRecord::Migration[8.0]
  def change
    # Простой индекс
    add_index :users, :email
    
    # Уникальный индекс
    add_index :users, :username, unique: true
    
    # Составной индекс
    add_index :users, [:last_name, :first_name]
    
    # Именованный индекс
    add_index :users, :email, name: "index_users_on_email_address"
    
    # Условный индекс (PostgreSQL)
    add_index :users, :created_at, where: "active = true"
    
    # Индекс с порядком
    add_index :users, [:last_name, :created_at], 
              order: { last_name: :asc, created_at: :desc }
    
    # Функциональный индекс (PostgreSQL)
    add_index :users, "lower(email)", name: "index_users_on_lower_email"
    
    # Concurrent индекс (PostgreSQL) - не блокирует таблицу
    add_index :users, :email, algorithm: :concurrently
    
    # Удаление индекса
    remove_index :users, :email
    remove_index :users, column: [:last_name, :first_name]
    remove_index :users, name: "index_users_on_email_address"
  end
end
```

## Foreign Keys

### Управление foreign keys
```ruby
class AddForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Добавление foreign key
    add_foreign_key :posts, :users
    
    # С опциями
    add_foreign_key :posts, :users,
                    column: :author_id,
                    primary_key: :uuid,
                    on_delete: :cascade,
                    on_update: :cascade
    
    # on_delete опции:
    # - :nullify (default) - установить NULL
    # - :cascade - удалить зависимые записи
    # - :restrict - запретить удаление
    
    # Удаление foreign key
    remove_foreign_key :posts, :users
    remove_foreign_key :posts, column: :author_id
    
    # При создании таблицы
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, foreign_key: { to_table: :users }
    end
  end
end
```

## Обратимые и необратимые миграции

### up/down методы
```ruby
class ComplexMigration < ActiveRecord::Migration[8.0]
  def up
    # Прямая миграция
    create_table :temp_users do |t|
      t.string :name
    end
    
    execute <<-SQL
      INSERT INTO temp_users (name)
      SELECT name FROM users WHERE active = true
    SQL
    
    drop_table :users
    rename_table :temp_users, :users
  end
  
  def down
    # Откат миграции
    rename_table :users, :temp_users
    
    create_table :users do |t|
      t.string :name
      t.boolean :active
    end
    
    execute <<-SQL
      INSERT INTO users (name, active)
      SELECT name, true FROM temp_users
    SQL
    
    drop_table :temp_users
  end
end
```

### reversible блоки
```ruby
class AddCheckConstraint < ActiveRecord::Migration[8.0]
  def change
    reversible do |direction|
      direction.up do
        execute <<-SQL
          ALTER TABLE products
          ADD CONSTRAINT price_check
          CHECK (price > 0)
        SQL
      end
      
      direction.down do
        execute <<-SQL
          ALTER TABLE products
          DROP CONSTRAINT price_check
        SQL
      end
    end
  end
end
```

## SQL выполнение

### execute для сырого SQL
```ruby
class AddComplexConstraint < ActiveRecord::Migration[8.0]
  def up
    # Добавление CHECK constraint (PostgreSQL)
    execute <<-SQL
      ALTER TABLE orders
      ADD CONSTRAINT valid_total
      CHECK (total >= 0 AND total = subtotal + tax - discount)
    SQL
    
    # Создание триггера (PostgreSQL)
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at();
    SQL
    
    # Создание view
    execute <<-SQL
      CREATE VIEW active_users AS
      SELECT * FROM users
      WHERE active = true AND deleted_at IS NULL
    SQL
  end
  
  def down
    execute "DROP VIEW IF EXISTS active_users"
    execute "DROP TRIGGER IF EXISTS update_users_updated_at ON users"
    execute "DROP FUNCTION IF EXISTS update_updated_at()"
    execute "ALTER TABLE orders DROP CONSTRAINT valid_total"
  end
end
```

## Безопасные миграции

### Strong Migrations gem patterns
```ruby
class SafeMigration < ActiveRecord::Migration[8.0]
  # Отключение транзакций для больших таблиц
  disable_ddl_transaction!
  
  def change
    # Безопасное добавление индекса
    add_index :users, :email, algorithm: :concurrently
    
    # Безопасное добавление колонки с default
    add_column :users, :score, :integer
    change_column_default :users, :score, 0
    
    # Batch обновление вместо default
    User.in_batches.update_all(score: 0)
  end
end
```

### Паттерн для zero-downtime deployments
```ruby
# Шаг 1: Добавить новую колонку (Deploy 1)
class AddNewEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :new_email, :string
  end
end

# Шаг 2: Синхронизация данных (Deploy 2)
class BackfillNewEmail < ActiveRecord::Migration[8.0]
  def up
    User.in_batches do |batch|
      batch.update_all("new_email = email")
    end
  end
end

# Шаг 3: Переключение на новую колонку (Deploy 3)
class SwitchToNewEmail < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :email, :old_email
    rename_column :users, :new_email, :email
  end
end

# Шаг 4: Удаление старой колонки (Deploy 4)
class RemoveOldEmail < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :users, :old_email }
  end
end
```

## Data миграции

### Миграции с данными
```ruby
class MigrateUserRoles < ActiveRecord::Migration[8.0]
  def up
    # Создание новой структуры
    create_table :roles do |t|
      t.string :name, null: false
      t.timestamps
    end
    
    add_reference :users, :role, foreign_key: true
    
    # Миграция данных
    admin_role = Role.create!(name: "admin")
    user_role = Role.create!(name: "user")
    
    User.where(admin: true).update_all(role_id: admin_role.id)
    User.where(admin: false).update_all(role_id: user_role.id)
    
    # Удаление старой колонки
    remove_column :users, :admin
  end
  
  def down
    add_column :users, :admin, :boolean, default: false
    
    User.joins(:role).where(roles: { name: "admin" }).update_all(admin: true)
    
    remove_reference :users, :role
    drop_table :roles
  end
end
```

## Schema файл

### db/schema.rb
```ruby
# Автоматически генерируется, НЕ редактируйте вручную!
ActiveRecord::Schema[8.0].define(version: 2024_01_15_123456) do
  # PostgreSQL extensions
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "pg_trgm"
  
  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end
  
  add_foreign_key "posts", "users"
end
```

## Команды миграций

```bash
# Выполнить миграции
rails db:migrate

# Откатить последнюю миграцию
rails db:rollback

# Откатить N миграций
rails db:rollback STEP=3

# Мигрировать к конкретной версии
rails db:migrate VERSION=20240115123456

# Проверить статус миграций
rails db:migrate:status

# Создать БД и выполнить миграции
rails db:setup

# Сбросить и пересоздать БД
rails db:reset

# Выполнить конкретную миграцию
rails db:migrate:up VERSION=20240115123456

# Откатить конкретную миграцию
rails db:migrate:down VERSION=20240115123456

# Повторить миграцию (down + up)
rails db:migrate:redo VERSION=20240115123456
```

## Рекомендации для Claude Code

1. **Обратимость** - всегда пишите обратимые миграции
2. **Безопасность** - используйте concurrent индексы для больших таблиц
3. **Zero-downtime** - разбивайте сложные изменения на этапы
4. **Не изменяйте старые миграции** - создавайте новые
5. **Тестируйте rollback** - проверяйте откат миграций
