# Rails Testing - Тестирование

## Структура тестов

### Организация тестов (RSpec)
```
spec/
├── models/
│   └── user_spec.rb
├── controllers/
│   └── users_controller_spec.rb
├── requests/
│   └── api/
│       └── v1/
│           └── users_spec.rb
├── features/
│   └── user_registration_spec.rb
├── views/
│   └── users/
│       └── index.html.erb_spec.rb
├── helpers/
│   └── application_helper_spec.rb
├── mailers/
│   └── user_mailer_spec.rb
├── jobs/
│   └── send_email_job_spec.rb
├── services/
│   └── user_service_spec.rb
├── support/
│   ├── factory_bot.rb
│   ├── database_cleaner.rb
│   └── helpers/
└── rails_helper.rb
└── spec_helper.rb
```

## RSpec конфигурация

### spec/rails_helper.rb
```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'capybara/rspec'
require 'webmock/rspec'

# Подключение support файлов
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Database cleaner
  config.use_transactional_fixtures = false
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end
  
  config.before(:each) do
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # FactoryBot
  config.include FactoryBot::Syntax::Methods
  
  # Devise helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  
  # Custom helpers
  config.include RequestSpecHelper, type: :request
  config.include FeatureSpecHelper, type: :feature
  
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

## Model тесты

### Базовые model specs
```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # Фабрики
  let(:user) { build(:user) }
  let(:admin) { create(:user, :admin) }
  
  # Валидации
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:password).is_at_least(8) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid').for(:email) }
    
    context 'custom validations' do
      it 'validates email domain' do
        user = build(:user, email: 'user@blocked.com')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('domain is blocked')
      end
    end
  end
  
  # Ассоциации
  describe 'associations' do
    it { should belong_to(:organization).optional }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:comments).through(:posts) }
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_one_attached(:avatar) }
    it { should have_many_attached(:documents) }
  end
  
  # Scopes
  describe 'scopes' do
    describe '.active' do
      let!(:active_user) { create(:user, active: true) }
      let!(:inactive_user) { create(:user, active: false) }
      
      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end
    
    describe '.recent' do
      it 'orders by created_at desc' do
        old_user = create(:user, created_at: 1.week.ago)
        new_user = create(:user, created_at: 1.day.ago)
        
        expect(User.recent.first).to eq(new_user)
        expect(User.recent.last).to eq(old_user)
      end
    end
  end
  
  # Callbacks
  describe 'callbacks' do
    describe 'before_validation' do
      it 'normalizes email' do
        user = build(:user, email: '  USER@EXAMPLE.COM  ')
        user.valid?
        expect(user.email).to eq('user@example.com')
      end
    end
    
    describe 'after_create' do
      it 'sends welcome email' do
        expect { create(:user) }
          .to have_enqueued_job(SendWelcomeEmailJob)
      end
    end
  end
  
  # Instance methods
  describe '#full_name' do
    it 'returns concatenated first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
    
    it 'handles nil values' do
      user = build(:user, first_name: nil, last_name: 'Doe')
      expect(user.full_name).to eq('Doe')
    end
  end
  
  # Class methods
  describe '.find_by_email' do
    let!(:user) { create(:user, email: 'Test@Example.com') }
    
    it 'finds user case-insensitively' do
      expect(User.find_by_email('test@example.com')).to eq(user)
    end
  end
end
```

## Controller тесты

### Controller specs (устаревает, используйте request specs)
```ruby
# spec/controllers/users_controller_spec.rb
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  
  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns @users' do
      users = create_list(:user, 3)
      get :index
      expect(assigns(:users)).to match_array(users)
    end
  end
  
  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) { { user: attributes_for(:user) } }
      
      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end
      
      it 'redirects to user' do
        post :create, params: valid_params
        expect(response).to redirect_to(User.last)
      end
    end
    
    context 'with invalid params' do
      let(:invalid_params) { { user: { email: '' } } }
      
      it 'does not create user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end
      
      it 'renders new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end
end
```

## Request тесты (рекомендуется)

### Request specs
```ruby
# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) { attributes_for(:user) }
  let(:invalid_attributes) { { email: '' } }
  
  describe 'GET /users' do
    it 'returns success' do
      get users_path
      expect(response).to have_http_status(:success)
    end
    
    it 'displays users' do
      users = create_list(:user, 3)
      get users_path
      
      users.each do |user|
        expect(response.body).to include(user.name)
      end
    end
  end
  
  describe 'POST /users' do
    context 'with valid parameters' do
      it 'creates a new User' do
        expect {
          post users_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end
      
      it 'redirects to the created user' do
        post users_path, params: { user: valid_attributes }
        expect(response).to redirect_to(user_path(User.last))
        follow_redirect!
        expect(response.body).to include('User was successfully created')
      end
    end
    
    context 'with invalid parameters' do
      it 'does not create a new User' do
        expect {
          post users_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end
      
      it 'returns unprocessable entity status' do
        post users_path, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'authentication' do
    it 'requires authentication for edit' do
      get edit_user_path(user)
      expect(response).to redirect_to(login_path)
    end
    
    it 'allows authenticated access' do
      sign_in user
      get edit_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end
end
```

### API request specs
```ruby
# spec/requests/api/v1/users_spec.rb
require 'rails_helper'

RSpec.describe 'API V1 Users', type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{user.api_token}" } }
  
  describe 'GET /api/v1/users' do
    let!(:users) { create_list(:user, 3) }
    
    before { get '/api/v1/users', headers: headers }
    
    it 'returns users' do
      expect(json).not_to be_empty
      expect(json.size).to eq(3)
    end
    
    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
  
  describe 'POST /api/v1/users' do
    let(:valid_attributes) { { user: attributes_for(:user) } }
    
    context 'when request is valid' do
      before { post '/api/v1/users', params: valid_attributes, headers: headers }
      
      it 'creates a user' do
        expect(json['email']).to eq(valid_attributes[:user][:email])
      end
      
      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
    
    context 'when request is invalid' do
      let(:invalid_attributes) { { user: { email: 'invalid' } } }
      
      before { post '/api/v1/users', params: invalid_attributes, headers: headers }
      
      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
      
      it 'returns validation errors' do
        expect(json['errors']).to include('email')
      end
    end
  end
  
  # Helper метод для парсинга JSON
  def json
    JSON.parse(response.body)
  end
end
```

## System/Feature тесты

### System tests (Rails 5.1+)
```ruby
# spec/system/user_registration_spec.rb
require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  scenario 'User signs up with valid data' do
    visit root_path
    click_link 'Sign Up'
    
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    
    click_button 'Sign Up'
    
    expect(page).to have_content('Welcome! You have signed up successfully.')
    expect(page).to have_content('user@example.com')
  end
  
  scenario 'User sees errors with invalid data' do
    visit sign_up_path
    
    fill_in 'Email', with: 'invalid'
    fill_in 'Password', with: '123'
    
    click_button 'Sign Up'
    
    expect(page).to have_content("Email is invalid")
    expect(page).to have_content("Password is too short")
  end
end
```

### Feature specs с Capybara
```ruby
# spec/features/user_management_spec.rb
require 'rails_helper'

RSpec.feature 'User Management', type: :feature do
  let(:admin) { create(:user, :admin) }
  
  background do
    sign_in admin
  end
  
  scenario 'Admin creates a new user', js: true do
    visit admin_users_path
    click_link 'New User'
    
    within('#user-form') do
      fill_in 'Name', with: 'John Doe'
      fill_in 'Email', with: 'john@example.com'
      select 'Active', from: 'Status'
      check 'Send welcome email'
    end
    
    click_button 'Create User'
    
    expect(page).to have_content('User was successfully created')
    expect(page).to have_content('John Doe')
    
    # Проверка Turbo Stream обновления
    within('#users-count') do
      expect(page).to have_content('Total: 2')
    end
  end
  
  scenario 'Admin deletes a user' do
    user = create(:user)
    visit admin_users_path
    
    within("#user-#{user.id}") do
      accept_confirm { click_link 'Delete' }
    end
    
    expect(page).to have_content('User was successfully deleted')
    expect(page).not_to have_content(user.email)
  end
end
```

## Фабрики (FactoryBot)

### Определение фабрик
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    active { true }
    
    # Traits
    trait :admin do
      role { 'admin' }
      after(:create) do |user|
        user.add_role(:admin)
      end
    end
    
    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/avatar.jpg')),
          filename: 'avatar.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
    
    trait :with_posts do
      transient do
        posts_count { 3 }
      end
      
      after(:create) do |user, evaluator|
        create_list(:post, evaluator.posts_count, user: user)
      end
    end
    
    # Вложенные фабрики
    factory :admin_user do
      role { 'admin' }
    end
  end
end

# Использование
user = create(:user)
admin = create(:user, :admin)
user_with_avatar = create(:user, :with_avatar)
user_with_posts = create(:user, :with_posts, posts_count: 5)
```

## Тестирование Jobs

```ruby
# spec/jobs/send_email_job_spec.rb
require 'rails_helper'

RSpec.describe SendEmailJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    
    it 'sends email' do
      expect {
        SendEmailJob.perform_now(user.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    
    it 'handles missing user' do
      expect {
        SendEmailJob.perform_now(999)
      }.not_to raise_error
    end
  end
  
  describe 'enqueuing' do
    let(:user) { create(:user) }
    
    it 'enqueues job' do
      expect {
        SendEmailJob.perform_later(user.id)
      }.to have_enqueued_job(SendEmailJob)
        .with(user.id)
        .on_queue('default')
    end
  end
end
```

## Тестирование Mailers

```ruby
# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#welcome_email' do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.welcome_email(user) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome to MyApp')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@myapp.com'])
    end
    
    it 'renders the body' do
      expect(mail.body.encoded).to match(user.name)
      expect(mail.body.encoded).to include('Welcome')
    end
    
    it 'includes activation link' do
      expect(mail.body.encoded).to include(activation_url(user.activation_token))
    end
  end
end
```

## Mocks и Stubs

```ruby
RSpec.describe PaymentService do
  let(:service) { described_class.new }
  
  describe '#process' do
    it 'charges credit card' do
      # Stub
      payment_gateway = double('PaymentGateway')
      allow(payment_gateway).to receive(:charge).and_return(true)
      
      # Mock with expectation
      expect(payment_gateway).to receive(:charge)
        .with(amount: 100, currency: 'USD')
        .and_return(success: true, transaction_id: '123')
      
      result = service.process(payment_gateway, 100)
      expect(result).to be_successful
    end
    
    it 'handles API errors' do
      allow(ExternalAPI).to receive(:call)
        .and_raise(ExternalAPI::Error, 'Connection failed')
      
      expect { service.sync_data }.not_to raise_error
      expect(service.errors).to include('Connection failed')
    end
  end
end
```

## Рекомендации для Claude Code

1. **Test-First** - пишите тесты перед кодом (TDD)
2. **Изоляция** - тестируйте одну вещь за раз
3. **Factories over Fixtures** - используйте FactoryBot
4. **Request specs over Controller specs** - более близки к реальности
5. **Быстрые тесты** - минимизируйте обращения к БД
