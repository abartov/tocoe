class AddSequenceNumberToEmbodiment < ActiveRecord::Migration[7.1]
  def change
    add_column :embodiments, :sequence_number, :integer
  end
end
