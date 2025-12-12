class PeopleToc < ApplicationRecord
  belongs_to :person
  belongs_to :toc

  validates :person_id, uniqueness: { scope: :toc_id }
end
