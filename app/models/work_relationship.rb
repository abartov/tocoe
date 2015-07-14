class WorkRelationship < ActiveRecord::Base
  belongs_to :work1
  belongs_to :work2
  belongs_to :creator # TODO: link to User entity
  belongs_to :reviewer # TODO: link to User entity
end
