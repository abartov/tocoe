class AddLocAndGutenbergIdsToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :loc_id, :string
    add_column :people, :gutenberg_id, :integer

    add_index :people, :loc_id
    add_index :people, :gutenberg_id
  end
end
