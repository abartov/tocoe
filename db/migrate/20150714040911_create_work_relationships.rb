class CreateWorkRelationships < ActiveRecord::Migration
  def change
    create_table :work_relationships do |t|
      t.references :work1, index: true, foreign_key: true
      t.references :work2, index: true, foreign_key: true
      t.string :reltype
      t.references :creator, index: true, foreign_key: true
      t.references :reviewer, index: true, foreign_key: true
      t.string :status

      t.timestamps null: false
    end
  end
end
