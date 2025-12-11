class AddSourceToTocs < ActiveRecord::Migration[7.2]
  def change
    add_column :tocs, :source, :string
    add_index :tocs, :source

    # Backfill existing records based on book_uri
    reversible do |dir|
      dir.up do
        # Set source to 'gutenberg' for Gutenberg books
        execute <<-SQL
          UPDATE tocs
          SET source = 'gutenberg'
          WHERE book_uri LIKE '%gutenberg.org%'
        SQL

        # Set source to 'openlibrary' for OpenLibrary books
        execute <<-SQL
          UPDATE tocs
          SET source = 'openlibrary'
          WHERE book_uri LIKE '%openlibrary.org%'
        SQL
      end
    end
  end
end
