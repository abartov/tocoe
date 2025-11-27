require 'rails_helper'

RSpec.describe Manifestation, type: :model do
  describe 'associations' do
    it 'has many embodiments' do
      manifestation = Manifestation.create!(title: "Test Manifestation")
      expression = Expression.create!(title: "Test Expression")
      embodiment = Embodiment.create!(manifestation: manifestation, expression: expression)

      expect(manifestation.embodiments).to include(embodiment)
    end

    it 'has one toc' do
      manifestation = Manifestation.create!(title: "Test Manifestation")
      toc = Toc.create!(manifestation: manifestation, status: :empty)

      expect(manifestation.toc).to eq(toc)
    end
  end
end
