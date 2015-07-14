class CreateRealizations < ActiveRecord::Migration
  def change
    create_table :realizations do |t|
      t.references :realizer, index: true, foreign_key: true
      t.references :expression, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
