class CreateManifestations < ActiveRecord::Migration
  def change
    create_table :manifestations do |t|
      t.string :title
      t.string :responsibility
      t.string :edition
      t.string :publisher
      t.string :publication_date
      t.string :publication_place
      t.string :series_statement
      t.text :comment

      t.timestamps null: false
    end
    add_index :manifestations, :title
  end
end
