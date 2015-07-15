class AddSequenceNumberToEmbodiment < ActiveRecord::Migration
  def change
    add_column :embodiments, :sequence_number, :integer
  end
end
