# Table of contents model
class Toc < ActiveRecord::Base
  belongs_to :manifestation, optional: true
  belongs_to :contributor, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true

  has_many :people_tocs, dependent: :destroy
  has_many :authors, through: :people_tocs, source: :person

  enum :status, { empty: 'empty', pages_marked: 'pages_marked', transcribed: 'transcribed', verified: 'verified', error: 'error' }

  # Explicitly declare the attribute type for the source enum
  attribute :source, :integer
  enum :source, { openlibrary: 0, gutenberg: 1, local_upload: 2 }
  validate :contributor_cannot_be_reviewer

  before_validation :set_source_from_book_uri
  before_save :set_status_timestamps

  # Serialize book_data as JSON
  serialize :book_data, coder: JSON

  private

  def set_source_from_book_uri
    return if source.present? # Don't override if already set
    return if book_uri.blank?

    if book_uri.include?('gutenberg.org')
      self.source = :gutenberg
    elsif book_uri.include?('openlibrary.org')
      self.source = :openlibrary
    end
  end

  def contributor_cannot_be_reviewer
    if contributor_id.present? && reviewer_id.present? && contributor_id == reviewer_id
      errors.add(:reviewer_id, 'cannot be the same as the contributor')
    end
  end

  def set_status_timestamps
    if status_changed?
      case status
      when 'transcribed'
        self.transcribed_at = Time.current
      when 'verified'
        self.verified_at = Time.current
      end
    end
  end
end
