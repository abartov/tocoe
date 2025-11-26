class Embodiment < ActiveRecord::Base
  belongs_to :expression
  belongs_to :manifestation
  has_many :aboutnesses, dependent: :destroy
end
