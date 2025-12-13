class CreateEmbodiments < ActiveRecord::Migration[7.1]
  def change
    create_table :embodiments do |t|
      t.bigint :expression_id
      t.bigint :manifestation_id
      t.string :reltype

      t.timestamps null: false
    end
    add_index :embodiments, :expression_id
    add_index :embodiments, :manifestation_id
  end
end
