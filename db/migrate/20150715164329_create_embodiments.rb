class CreateEmbodiments < ActiveRecord::Migration
  def change
    create_table :embodiments do |t|
      t.integer :expression_id
      t.integer :manifestation_id
      t.string :reltype

      t.timestamps null: false
    end
    add_index :embodiments, :expression_id
    add_index :embodiments, :manifestation_id
  end
end
