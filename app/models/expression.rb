class Expression < ActiveRecord::Base
  validates_presence_of :title, :message => "cannot be blank"

  # work-expression relationships
  has_one :reification
  has_one :work, through: :reification

  # expression-person relationships
  has_many :realizations
  has_many :realizers, through: :realizations, class_name: :Person

  # expression-expression relationships
  has_many :expression_relationships, foreign_key: :exp1_id, dependent: :destroy
  has_many :reverse_expression_relationships, class_name: :ExpressionRelationship, foreign_key: :exp2_id, dependent: :destroy
  has_many :related_expressions, through: :expression_relationships, source: :exp2

  # expression-mainfestation relationships
  has_many :embodiments
  has_many :manifestations, :through => :embodiments
 
  def append_component(new_component)
    rel = ExpressionRelationship.new(exp1_id: self.id, exp2_id: new_component.id, reltype: :aggregation) # TODO: add creator, status, etc.
    rel.save!
  end

  def component_expressions
    expression_relationships.where(reltype: :aggregation).collect { |rel| rel.exp2 }
  end
  def container_expressions
    reverse_expression_relationships.where(reltype: :aggregation).collect { |rel| rel.exp1 }
  end
  def successor_expression
    ret = expression_relationships.where(reltype: :sequence).first
    unless ret.nil?
      ret = ret.exp2
    end
    return ret
  end
  def predecessor_expression
    ret = reverse_expression_relationships.where(reltype: :sequence).first
    unless ret.nil?
      ret = ret.exp1
    end
    return ret
  end

  # insert exp after self
  def insert_expression(exp)
    succ = successor_expression
    
    #create a new successor
    unless succ.nil?
      current_rel = ExpressionRelationship.where(exp1: self, reltype: :sequence)
      current_rel.exp1 = exp # link old successor to this new inserted one
      current_rel.save!
    end  
    rel = ExpressionRelationship.new(exp1: self, exp2: exp, reltype: :sequence)
    rel.save!
  end
end

