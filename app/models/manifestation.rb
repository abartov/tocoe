class Manifestation < ActiveRecord::Base

  has_many :embodiments
  has_many :expressions, :through => :embodiments
  has_one :toc

end
