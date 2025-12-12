class Aboutness < ActiveRecord::Base
  belongs_to :embodiment
  belongs_to :contributor, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true

  validates :embodiment_id, presence: true
  validates :subject_heading_uri, presence: true
  validates :source_name, presence: true, inclusion: { in: %w[LCSH Wikidata] }
  validates :subject_heading_label, presence: true
  validates :status, presence: true, inclusion: { in: %w[proposed verified] }

  # Ensure we don't create duplicate aboutnesses
  validates :subject_heading_uri, uniqueness: { scope: :embodiment_id }

  # Scopes for filtering
  scope :proposed, -> { where(status: 'proposed') }
  scope :verified, -> { where(status: 'verified') }
  scope :user_contributed, -> { where.not(contributor_id: nil) }
  scope :imported, -> { where(contributor_id: nil) }

  # Check if a user can verify this aboutness
  def verifiable_by?(user)
    return false unless user
    return false if status == 'verified'
    return false if contributor_id == user.id
    true
  end
end
