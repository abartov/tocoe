require 'rails_helper'

RSpec.describe Aboutness, type: :model do
  let(:embodiment) { Embodiment.create!(expression: Expression.create!(title: "Test"), manifestation: Manifestation.create!(title: "Test")) }

  describe 'validations' do
    it 'requires an embodiment_id' do
      aboutness = Aboutness.new(
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:embodiment_id]).to include("can't be blank")
    end

    it 'requires a subject_heading_uri' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:subject_heading_uri]).to include("can't be blank")
    end

    it 'requires a source_name' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        subject_heading_label: 'Whales'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:source_name]).to include("can't be blank")
    end

    it 'requires a subject_heading_label' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:subject_heading_label]).to include("can't be blank")
    end

    it 'validates source_name is LCSH or Wikidata' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'InvalidSource',
        subject_heading_label: 'Whales'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:source_name]).to include('is not included in the list')
    end

    it 'prevents duplicate subject_heading_uri for the same embodiment' do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )

      duplicate = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subject_heading_uri]).to include('has already been taken')
    end

    it 'allows same subject_heading_uri for different embodiments' do
      embodiment2 = Embodiment.create!(expression: Expression.create!(title: "Test 2"), manifestation: Manifestation.create!(title: "Test 2"))

      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )

      aboutness2 = Aboutness.new(
        embodiment: embodiment2,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(aboutness2).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to an embodiment' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(aboutness.embodiment).to eq(embodiment)
    end
  end

  describe 'creating a valid aboutness' do
    it 'succeeds with valid LCSH attributes' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
      expect(aboutness).to be_persisted
      expect(aboutness.source_name).to eq('LCSH')
    end

    it 'succeeds with valid Wikidata attributes' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'http://www.wikidata.org/entity/Q42',
        source_name: 'Wikidata',
        subject_heading_label: 'Douglas Adams'
      )
      expect(aboutness).to be_persisted
      expect(aboutness.source_name).to eq('Wikidata')
    end
  end
end
