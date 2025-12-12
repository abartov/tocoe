class Person < ActiveRecord::Base
  validates_presence_of :name, :message => "cannot be blank"
  has_many :people_works
  has_many :works, through: :people_works
  has_many :people_tocs
  has_many :tocs, through: :people_tocs
end
