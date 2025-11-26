require 'rails_helper'

RSpec.describe Embodiment, type: :model do
  let(:expression) { Expression.create!(title: "Test Expression") }
  let(:manifestation) { Manifestation.create!(title: "Test Manifestation") }
  let(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }

  describe 'associations' do
    it 'has many aboutnesses' do
      aboutness1 = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      aboutness2 = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'http://www.wikidata.org/entity/Q42',
        source_name: 'Wikidata',
        subject_heading_label: 'Douglas Adams'
      )

      expect(embodiment.aboutnesses.count).to eq(2)
      expect(embodiment.aboutnesses).to include(aboutness1, aboutness2)
    end

    it 'destroys associated aboutnesses when embodiment is destroyed' do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )

      expect { embodiment.destroy }.to change { Aboutness.count }.by(-1)
    end
  end
end
