class CreatePeopleWorks < ActiveRecord::Migration[7.1]
  def change
    create_table :people_works do |t|
      t.references :person, index: true, foreign_key: true
      t.references :work, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
