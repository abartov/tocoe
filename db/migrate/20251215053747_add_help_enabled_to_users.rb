class AddHelpEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :help_enabled, :boolean, default: true, null: false
    add_index :users, :help_enabled
  end
end
