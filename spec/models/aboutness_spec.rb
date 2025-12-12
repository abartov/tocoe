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

    it 'validates status is proposed or verified' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'invalid_status'
      )
      expect(aboutness).not_to be_valid
      expect(aboutness.errors[:status]).to include('is not included in the list')
    end

    it 'accepts proposed status' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'proposed'
      )
      expect(aboutness).to be_valid
    end

    it 'accepts verified status' do
      aboutness = Aboutness.new(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'verified'
      )
      expect(aboutness).to be_valid
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

    it 'belongs to a contributor' do
      user = User.create!(email: 'contributor@example.com', password: 'password123', password_confirmation: 'password123')
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        contributor: user,
        status: 'proposed'
      )
      expect(aboutness.contributor).to eq(user)
    end

    it 'belongs to a reviewer' do
      contributor = User.create!(email: 'contributor@example.com', password: 'password123', password_confirmation: 'password123')
      reviewer = User.create!(email: 'reviewer@example.com', password: 'password123', password_confirmation: 'password123')
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        contributor: contributor,
        reviewer: reviewer,
        status: 'verified'
      )
      expect(aboutness.reviewer).to eq(reviewer)
    end
  end

  describe 'scopes' do
    let!(:proposed_aboutness) do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'proposed',
        contributor_id: 1
      )
    end

    let!(:verified_aboutness) do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85000001',
        source_name: 'LCSH',
        subject_heading_label: 'Test Subject',
        status: 'verified',
        contributor_id: nil
      )
    end

    it 'filters by proposed status' do
      expect(Aboutness.proposed).to include(proposed_aboutness)
      expect(Aboutness.proposed).not_to include(verified_aboutness)
    end

    it 'filters by verified status' do
      expect(Aboutness.verified).to include(verified_aboutness)
      expect(Aboutness.verified).not_to include(proposed_aboutness)
    end

    it 'filters user contributed aboutnesses' do
      expect(Aboutness.user_contributed).to include(proposed_aboutness)
      expect(Aboutness.user_contributed).not_to include(verified_aboutness)
    end

    it 'filters imported aboutnesses' do
      expect(Aboutness.imported).to include(verified_aboutness)
      expect(Aboutness.imported).not_to include(proposed_aboutness)
    end
  end

  describe '#verifiable_by?' do
    let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password123', password_confirmation: 'password123') }
    let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password123', password_confirmation: 'password123') }

    it 'returns false when user is nil' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'proposed'
      )
      expect(aboutness.verifiable_by?(nil)).to be false
    end

    it 'returns false when status is verified' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'verified'
      )
      expect(aboutness.verifiable_by?(reviewer)).to be false
    end

    it 'returns false when user is the contributor' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'proposed',
        contributor: contributor
      )
      expect(aboutness.verifiable_by?(contributor)).to be false
    end

    it 'returns true when user is different from contributor and status is proposed' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://lccn.loc.gov/sh85146357',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'proposed',
        contributor: contributor
      )
      expect(aboutness.verifiable_by?(reviewer)).to be true
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
