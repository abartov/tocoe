# Table of contents model
class Toc < ActiveRecord::Base
  belongs_to :manifestation
  enum status: { empty: 'empty', pages_marked: 'pages_marked', transcribed: 'transcribed', verified: 'verified', error: 'error' }
end
