class WorkRelationship < ActiveRecord::Base
  belongs_to :work1, class_name: :Work
  belongs_to :work2, class_name: :Work
  belongs_to :creator # TODO: link to User entity
  belongs_to :reviewer # TODO: link to User entity:
end
