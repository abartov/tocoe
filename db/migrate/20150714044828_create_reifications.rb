class CreateReifications < ActiveRecord::Migration[7.1]
  def change
    create_table :reifications do |t|
      t.references :work, index: true, foreign_key: true, type: :bigint
      t.references :expression, index: true, foreign_key: true, type: :bigint
      t.string :reltype

      t.timestamps null: false
    end
  end
end
