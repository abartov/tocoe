class Work < ActiveRecord::Base
  validates_presence_of :title, :message => "cannot be blank"

  #has_many :component_works, through: :work_relationships
  has_many :people_works
  has_many :creators, through: :people_works, source: :person

  # work-work relationships
  has_many :work_relationships, foreign_key: :work1_id, dependent: :destroy, table_name: :work_relationships
  has_many :reverse_work_relationships, class_name: :WorkRelationship, foreign_key: :work2_id, dependent: :destroy
  has_many :related_works, through: :work_relationships, source: :work2

  def component_works
    work_relationships.where(reltype: :aggregation).collect { |rel| rel.work2 }
  end
  def container_works
    reverse_work_relationships.where(reltype: :aggregation).collect { |rel| rel.work1 }
  end
end
