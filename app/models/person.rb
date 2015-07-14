class Person < ActiveRecord::Base
  validates_presence_of :name, :message => "cannot be blank"
  has_many :people_works
  has_many :works, through: :people_works
end
