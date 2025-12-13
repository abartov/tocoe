class AddOpenLibraryIdToPerson < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :openlibrary_id, :string
    add_index :people, :openlibrary_id
  end
end
