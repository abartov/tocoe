class CreatePeopleTocs < ActiveRecord::Migration[7.2]
  def change
    create_table :people_tocs do |t|
      t.references :person, null: false, foreign_key: true
      t.references :toc, null: false, foreign_key: true

      t.timestamps
    end

    add_index :people_tocs, [:person_id, :toc_id], unique: true
  end
end
