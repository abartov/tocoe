class Work < ActiveRecord::Base
  validates_presence_of :title, :message => "cannot be blank"

  has_many :component_works, through: :work_relationships
  has_many :people_works
  has_many :creators, through: :people_works, source: :person
end
