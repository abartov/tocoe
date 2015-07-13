class CreateTocs < ActiveRecord::Migration
  def change
    create_table :tocs do |t|
      t.string :book_uri
      t.text :toc_body
      t.string :status
      t.integer :contributor_id
      t.integer :reviewer_id
      t.text :comments

      t.timestamps null: false
    end
    add_index :tocs, :book_uri, unique: true
    add_index :tocs, :contributor_id
    add_index :tocs, :reviewer_id
  end
end
