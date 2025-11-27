class AddAdminAndEditorToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :admin, :boolean, default: false
    add_column :users, :editor, :boolean, default: false
  end
end
