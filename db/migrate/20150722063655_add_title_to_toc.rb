class AddTitleToToc < ActiveRecord::Migration[7.1]
  def change
    add_column :tocs, :title, :string
  end
end
