# Table of contents model
class Toc < ActiveRecord::Base
  belongs_to :manifestation, optional: true
  belongs_to :contributor, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true
  enum :status, { empty: 'empty', pages_marked: 'pages_marked', transcribed: 'transcribed', verified: 'verified', error: 'error' }

  before_save :set_status_timestamps

  private

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
