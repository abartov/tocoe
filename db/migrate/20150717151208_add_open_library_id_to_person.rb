class AddOpenLibraryIdToPerson < ActiveRecord::Migration
  def change
    add_column :people, :openlibrary_id, :string
    add_index :people, :openlibrary_id
  end
end
