class PeopleWork < ActiveRecord::Base
  belongs_to :person
  belongs_to :work
end
