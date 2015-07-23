class AddManifestationIdToToc < ActiveRecord::Migration
  def change
    add_column :tocs, :manifestation_id, :integer
    add_index :tocs, :manifestation_id
  end
end
