class AddManifestationIdToToc < ActiveRecord::Migration[7.1]
  def change
    add_column :tocs, :manifestation_id, :bigint
    add_index :tocs, :manifestation_id
  end
end
