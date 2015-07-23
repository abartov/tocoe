class AddTitleToToc < ActiveRecord::Migration
  def change
    add_column :tocs, :title, :string
  end
end
