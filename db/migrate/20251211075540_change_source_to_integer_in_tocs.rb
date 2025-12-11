class ChangeSourceToIntegerInTocs < ActiveRecord::Migration[7.2]
  def up
    # Add temporary integer column
    add_column :tocs, :source_int, :integer

    # Convert existing string values to integers based on enum mapping
    # openlibrary: 0, gutenberg: 1, local_upload: 2
    execute <<-SQL
      UPDATE tocs
      SET source_int = CASE source
        WHEN 'openlibrary' THEN 0
        WHEN 'gutenberg' THEN 1
        WHEN 'local_upload' THEN 2
        ELSE NULL
      END
    SQL

    # Remove old string column and its index
    remove_index :tocs, :source
    remove_column :tocs, :source

    # Rename temporary column to source
    rename_column :tocs, :source_int, :source

    # Re-add index
    add_index :tocs, :source
  end

  def down
    # Add temporary string column
    add_column :tocs, :source_str, :string

    # Convert integers back to strings
    execute <<-SQL
      UPDATE tocs
      SET source_str = CASE source
        WHEN 0 THEN 'openlibrary'
        WHEN 1 THEN 'gutenberg'
        WHEN 2 THEN 'local_upload'
        ELSE NULL
      END
    SQL

    # Remove integer column and its index
    remove_index :tocs, :source
    remove_column :tocs, :source

    # Rename temporary column to source
    rename_column :tocs, :source_str, :source

    # Re-add index
    add_index :tocs, :source
  end
end
