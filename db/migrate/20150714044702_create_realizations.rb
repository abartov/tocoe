class CreateRealizations < ActiveRecord::Migration[7.1]
  def change
    create_table :realizations do |t|
      t.references :realizer, index: true, foreign_key: { to_table: :people }, type: :bigint
      t.references :expression, index: true, foreign_key: true, type: :bigint

      t.timestamps null: false
    end
  end
end
