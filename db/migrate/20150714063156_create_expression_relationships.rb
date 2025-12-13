class CreateExpressionRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :expression_relationships do |t|
      t.references :exp1, index: true, foreign_key: { to_table: :expressions }
      t.references :exp2, index: true, foreign_key: { to_table: :expressions }
      t.string :reltype
      t.references :creator, index: true, foreign_key: { to_table: :users }
      t.references :reviewer, index: true, foreign_key: { to_table: :users }
      t.string :status

      t.timestamps null: false
    end
  end
end
