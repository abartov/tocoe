class SetDefaultStatusForTocs < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tocs, :status, from: nil, to: 'empty'
  end
end
