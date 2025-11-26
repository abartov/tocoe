class Aboutness < ActiveRecord::Base
  belongs_to :embodiment

  validates :embodiment_id, presence: true
  validates :subject_heading_uri, presence: true
  validates :source_name, presence: true, inclusion: { in: %w[LCSH Wikidata] }
  validates :subject_heading_label, presence: true

  # Ensure we don't create duplicate aboutnesses
  validates :subject_heading_uri, uniqueness: { scope: :embodiment_id }
end
