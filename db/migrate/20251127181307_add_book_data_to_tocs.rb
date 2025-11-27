class AddBookDataToTocs < ActiveRecord::Migration[7.2]
  def change
    add_column :tocs, :book_data, :text
  end
end
