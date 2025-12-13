class AddVerificationToAboutnesses < ActiveRecord::Migration[7.2]
  def change
    add_column :aboutnesses, :contributor_id, :bigint
    add_column :aboutnesses, :reviewer_id, :bigint
    add_column :aboutnesses, :status, :string, default: 'verified'

    add_index :aboutnesses, :contributor_id
    add_index :aboutnesses, :reviewer_id
    add_index :aboutnesses, :status

    # Set status to 'verified' for all existing aboutnesses (imported data)
    # These have null contributor_id by default
    reversible do |dir|
      dir.up do
        execute "UPDATE aboutnesses SET status = 'verified' WHERE status IS NULL"
      end
    end
  end
end
