class Work < ActiveRecord::Base
  validates_presence_of :title, :message => "cannot be blank"

  has_many :people_works
  has_many :creators, through: :people_works, source: :person
  has_many :reifications, class_name: :Reification
  has_many :expressions, through: :reifications, source: :expression

  # work-work relationships
  has_many :work_relationships, foreign_key: :work1_id, dependent: :destroy
  has_many :reverse_work_relationships, class_name: :WorkRelationship, foreign_key: :work2_id, dependent: :destroy
  has_many :related_works, through: :work_relationships, source: :work2

  def append_component(new_component) # aggregation
    rel = WorkRelationship.new(work1_id: self.id, work2_id: new_component.id, reltype: :aggregation) # TODO: add creator, status, etc.
    rel.save!
  end
  def insert_after(new_successor) # sequence
    current_successor = successor_work
    unless current_successor.nil? # link current_successor to this new_successor 
      rel = WorkRelationship.where(work2_id: current_successor.id, reltype: :sequence)
      raise IntegrityError if rel.nil?
      rel.work1_id = new_successor.id
      rel.save!
    end
    rel = WorkRelationship.new(work1_id: self.id, work2_id: new_successor.id, reltype: :sequence)
    rel.save!
  end
  def component_works
    work_relationships.where(reltype: :aggregation).collect { |rel| rel.work2 }
  end
  def container_works
    reverse_work_relationships.where(reltype: :aggregation).collect { |rel| rel.work1 }
  end
  def successor_work
    ret = work_relationships.where(reltype: :sequence).first
    unless ret.nil?
      ret = ret.work2
    end
    return ret
  end
  def predecessor_work
    ret = reverse_work_relationships.where(reltype: :sequence).first
    unless ret.nil?
      ret = ret.work1
    end
    return ret
  end
  
  # work-work relationships not implemented for now: Equivalent; Derivative; Descriptive (review, criticism, annotated edition, exegesis), Companion (supplements, auxiliary materials like maps or companion CDs)
end
