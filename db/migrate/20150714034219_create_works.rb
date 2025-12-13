class CreateWorks < ActiveRecord::Migration[7.1]
  def change
    create_table :works do |t|
      t.string :title
      t.string :form
      t.string :creation_date
      t.text :comment
      t.string :status
      t.integer :superseded_by
      t.integer :wikidata_q

      t.timestamps null: false
    end
    add_index :works, :title
    add_index :works, :wikidata_q
  end
end
