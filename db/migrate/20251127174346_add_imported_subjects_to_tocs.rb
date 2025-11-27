class AddImportedSubjectsToTocs < ActiveRecord::Migration[7.2]
  def change
    add_column :tocs, :imported_subjects, :text
  end
end
