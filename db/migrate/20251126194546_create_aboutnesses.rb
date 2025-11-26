class CreateAboutnesses < ActiveRecord::Migration[7.2]
  def change
    create_table :aboutnesses do |t|
      t.integer :embodiment_id
      t.string :subject_heading_uri
      t.string :source_name
      t.string :subject_heading_label

      t.timestamps
    end

    add_index :aboutnesses, :embodiment_id
    add_index :aboutnesses, :source_name
  end
end
