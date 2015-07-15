class Manifestation < ActiveRecord::Base

  has_many :embodiments
  has_many :expressions, :through => :embodiments

end
