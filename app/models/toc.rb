# Table of contents model
class Toc < ActiveRecord::Base
  belongs_to :manifestation, optional: true
  belongs_to :contributor, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true
  enum :status, { empty: 'empty', pages_marked: 'pages_marked', transcribed: 'transcribed', verified: 'verified', error: 'error' }
end
