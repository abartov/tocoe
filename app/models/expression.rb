class Expression < ActiveRecord::Base
  validates_presence_of :title, :message => "cannot be blank"

  has_one :reification
  has_one :work, through: :reifications

  has_many :realizations
  has_many :realizers, through: :realizations, class_name: :Person
end
