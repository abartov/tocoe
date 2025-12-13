class CreatePeople < ActiveRecord::Migration[7.1]
  def change
    create_table :people do |t|
      t.string :name
      t.string :dates
      t.string :title
      t.string :affiliation
      t.string :country
      t.text :comment
      t.integer :viaf_id
      t.integer :wikidata_q

      t.timestamps null: false
    end
    add_index :people, :viaf_id
    add_index :people, :wikidata_q
  end
end
