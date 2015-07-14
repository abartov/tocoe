class CreateReifications < ActiveRecord::Migration
  def change
    create_table :reifications do |t|
      t.references :work, index: true, foreign_key: true
      t.references :expression, index: true, foreign_key: true
      t.string :reltype

      t.timestamps null: false
    end
  end
end
