class Realization < ActiveRecord::Base
  belongs_to :realizer, class_name: :Person
  belongs_to :expression
end
