class CreateExpressions < ActiveRecord::Migration
  def change
    create_table :expressions do |t|
      t.string :title
      t.string :publication_date
      t.string :creation_date
      t.string :language

      t.timestamps null: false
    end
    add_index :expressions, :title
    add_index :expressions, :language
  end
end
