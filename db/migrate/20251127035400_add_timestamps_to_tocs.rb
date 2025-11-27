class AddTimestampsToTocs < ActiveRecord::Migration[7.2]
  def change
    add_column :tocs, :transcribed_at, :datetime
    add_column :tocs, :verified_at, :datetime
  end
end
