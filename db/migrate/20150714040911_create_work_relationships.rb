class CreateWorkRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :work_relationships do |t|
      t.references :work1, index: true, foreign_key: { to_table: :works }, null: false, type: :bigint
      t.references :work2, index: true, foreign_key: { to_table: :works }, null: false, type: :bigint
      t.string :reltype
      t.references :creator, index: true, foreign_key: { to_table: :users }, type: :bigint
      t.references :reviewer, index: true, foreign_key: { to_table: :users }, type: :bigint
      t.string :status

      t.timestamps null: false
    end
  end
end
