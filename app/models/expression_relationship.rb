class ExpressionRelationship < ActiveRecord::Base
  belongs_to :exp1, class_name: :Expression
  belongs_to :exp2, class_name: :Expression
  belongs_to :creator
  belongs_to :reviewer
end
