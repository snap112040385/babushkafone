class AddEmailConfirmationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_confirmed, :boolean, default: false, null: false
    add_column :users, :email_confirmed_at, :datetime

    add_index :users, :email_confirmed
  end
end
