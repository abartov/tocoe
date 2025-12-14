# frozen_string_literal: true

# Service for matching people across multiple authority sources
class PersonMatcherService
  # Search for a person across all authority sources
  # @param query [String] The name to search for
  # @param candidates [Array<Hash>] Optional candidate identifications
  #   Example: [{ source: 'viaf', id: '113230702', label: 'Adams, Douglas' }]
  # @return [Hash] Results grouped by source
  def self.search_all(query:, candidates: [])
    new(query: query, candidates: candidates).search_all
  end

  # Fetch detailed information about a person from a specific source
  # @param source [String] The authority source ('viaf', 'wikidata', 'loc', 'database')
  # @param id [String, Integer] The identifier in that source
  # @return [Hash, nil] Detailed person information
  def self.fetch_details(source:, id:)
    new.fetch_details(source: source, id: id)
  end

  # Match a person to a target object (Toc, Work, Expression)
  # @param target_type [String] The type of object to associate with
  # @param target_id [Integer] The ID of the target object
  # @param source [String] The authority source
  # @param external_id [String, Integer] The ID in the external source
  # @param person_id [Integer, nil] Existing Person ID, or nil to create new
  # @return [Hash] Result with person record
  def self.match(target_type:, target_id:, source:, external_id:, person_id: nil)
    new.match(
      target_type: target_type,
      target_id: target_id,
      source: source,
      external_id: external_id,
      person_id: person_id
    )
  end

  def initialize(query: nil, candidates: [])
    @query = query
    @candidates = candidates || []
  end

  def search_all
    return empty_results if @query.blank?

    {
      database: search_database,
      viaf: search_viaf,
      wikidata: search_wikidata,
      loc: search_loc
    }
  end

  def fetch_details(source:, id:)
    case source.to_s
    when 'database'
      fetch_database_details(id)
    when 'viaf'
      fetch_viaf_details(id)
    when 'wikidata'
      fetch_wikidata_details(id)
    when 'loc'
      fetch_loc_details(id)
    else
      nil
    end
  end

  def match(target_type:, target_id:, source:, external_id:, person_id: nil)
    # Find or create Person record
    person = if person_id.present?
               Person.find(person_id)
             else
               create_person_from_source(source: source, external_id: external_id)
             end

    return { success: false, error: 'Person not found or could not be created' } unless person

    # Create association based on target type
    success = case target_type.to_s
              when 'Toc'
                associate_with_toc(person, target_id)
              when 'Work'
                associate_with_work(person, target_id)
              when 'Expression'
                associate_with_expression(person, target_id)
              else
                false
              end

    if success
      { success: true, person: person }
    else
      { success: false, error: 'Failed to create association' }
    end
  end

  private

  def empty_results
    { database: [], viaf: [], wikidata: [], loc: [] }
  end

  # Database search
  def search_database
    return [] if @query.blank?

    people = Person.where('name LIKE ?', "%#{@query}%").limit(30)
    people.map { |person| format_database_result(person) }
  end

  def format_database_result(person)
    {
      source: 'database',
      id: person.id,
      person_id: person.id,
      label: person.name,
      dates: person.dates,
      country: person.country,
      is_candidate: false,
      in_database: true
    }
  end

  # VIAF search
  def search_viaf
    return [] if @query.blank?

    client = Viaf::Client.new
    results = client.search_person(@query)

    # Mark candidates and check if in database
    results.map do |result|
      viaf_id = result[:viaf_id]
      existing_person = Person.find_by(viaf_id: viaf_id)
      is_candidate = candidate?('viaf', viaf_id)

      {
        source: 'viaf',
        id: viaf_id,
        person_id: existing_person&.id,
        label: result[:label],
        dates: extract_dates_from_label(result[:label]),
        country: nil, # VIAF doesn't provide country in search results
        is_candidate: is_candidate,
        in_database: existing_person.present?
      }
    end.sort_by { |r| [r[:is_candidate] ? 0 : 1, r[:in_database] ? 0 : 1] }
  end

  # Wikidata search
  def search_wikidata
    return [] if @query.blank?

    client = SubjectHeadings::WikidataClient.new
    results = client.search(@query, count: 20)

    # Only include items that are humans (instance of Q5)
    human_results = results.select do |result|
      result[:instance_of]&.include?('human') || result[:instance_of]&.any? { |io| io =~ /human/i }
    end

    human_results.map do |result|
      wikidata_q = result[:entity_id]&.gsub('Q', '')&.to_i
      existing_person = wikidata_q ? Person.find_by(wikidata_q: wikidata_q) : nil
      is_candidate = candidate?('wikidata', wikidata_q)

      {
        source: 'wikidata',
        id: wikidata_q,
        person_id: existing_person&.id,
        label: result[:label],
        description: result[:description],
        dates: nil, # Will be fetched in details
        country: nil, # Will be fetched in details
        is_candidate: is_candidate,
        in_database: existing_person.present?
      }
    end.sort_by { |r| [r[:is_candidate] ? 0 : 1, r[:in_database] ? 0 : 1] }
  end

  # Library of Congress search
  def search_loc
    return [] if @query.blank?

    client = LibraryOfCongress::NameAuthorityClient.new
    results = client.search_person(@query)

    results.map do |result|
      loc_id = result[:loc_id]
      existing_person = Person.find_by(loc_id: loc_id)
      is_candidate = candidate?('loc', loc_id)

      {
        source: 'loc',
        id: loc_id,
        person_id: existing_person&.id,
        label: result[:label],
        dates: extract_dates_from_label(result[:label]),
        country: nil, # LoC doesn't provide country in search results
        is_candidate: is_candidate,
        in_database: existing_person.present?
      }
    end.sort_by { |r| [r[:is_candidate] ? 0 : 1, r[:in_database] ? 0 : 1] }
  end

  # Check if a result matches one of the candidates
  def candidate?(source, id)
    return false unless @candidates.respond_to?(:any?)

    @candidates.any? do |candidate|
      # Handle both Hash and ActionController::Parameters
      candidate_source = candidate.is_a?(Hash) ? candidate[:source] : candidate['source']
      candidate_id = candidate.is_a?(Hash) ? candidate[:id] : candidate['id']

      candidate_source.to_s == source.to_s && candidate_id.to_s == id.to_s
    end
  end

  # Extract dates from label (e.g., "Adams, Douglas, 1952-2001" -> "1952-2001")
  def extract_dates_from_label(label)
    match = label.match(/(\d{4}-\d{4}|\d{4}-present|\d{4}-)/)
    match ? match[1] : nil
  end

  # Fetch detailed information from database
  def fetch_database_details(person_id)
    person = Person.find_by(id: person_id)
    return nil unless person

    {
      full_name: person.name,
      dates: person.dates,
      country: person.country,
      title: person.title,
      affiliation: person.affiliation,
      comment: person.comment,
      authority_ids: {
        viaf: person.viaf_id,
        wikidata: person.wikidata_q,
        loc: person.loc_id,
        openlibrary: person.openlibrary_id,
        gutenberg: person.gutenberg_id
      }
    }
  end

  # Fetch detailed information from VIAF
  def fetch_viaf_details(viaf_id)
    # VIAF doesn't have a simple details API, would need to parse XML
    # For now, return basic info
    { viaf_id: viaf_id }
  end

  # Fetch detailed information from Wikidata
  def fetch_wikidata_details(wikidata_q)
    client = SubjectHeadings::WikidataClient.new
    entity_id = "Q#{wikidata_q}"

    # Fetch entity data
    entities = client.send(:fetch_entities, [entity_id])
    entity = entities[entity_id]
    return nil unless entity

    # Extract useful information from claims
    claims = entity['claims'] || {}

    {
      wikidata_id: entity_id,
      occupations: extract_claim_labels(claims['P106'], client), # P106 = occupation
      notable_works: extract_claim_labels(claims['P800'], client), # P800 = notable work
      birth_date: extract_time_claim(claims['P569']), # P569 = date of birth
      death_date: extract_time_claim(claims['P570']), # P570 = date of death
      country: extract_claim_labels(claims['P27'], client)&.first, # P27 = country of citizenship
      authority_ids: {
        viaf: extract_string_claim(claims['P214']), # P214 = VIAF ID
        loc: extract_string_claim(claims['P244']), # P244 = LoC ID
        isni: extract_string_claim(claims['P213']) # P213 = ISNI
      }
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching Wikidata details for Q#{wikidata_q}: #{e.message}"
    nil
  end

  # Fetch detailed information from Library of Congress
  def fetch_loc_details(loc_id)
    # LoC doesn't have a simple details API in the suggest endpoint
    # For now, return basic info
    { loc_id: loc_id }
  end

  # Create a Person record from an external source
  def create_person_from_source(source:, external_id:)
    case source.to_s
    when 'viaf'
      create_person_from_viaf(external_id)
    when 'wikidata'
      create_person_from_wikidata(external_id)
    when 'loc'
      create_person_from_loc(external_id)
    else
      nil
    end
  end

  def create_person_from_viaf(viaf_id)
    # Search for more info
    client = Viaf::Client.new
    results = client.search_person(@query)
    result = results.find { |r| r[:viaf_id].to_s == viaf_id.to_s }

    return nil unless result

    Person.create!(
      name: result[:label],
      dates: extract_dates_from_label(result[:label]),
      viaf_id: viaf_id.to_i
    )
  rescue StandardError => e
    Rails.logger.error "Error creating person from VIAF #{viaf_id}: #{e.message}"
    nil
  end

  def create_person_from_wikidata(wikidata_q)
    details = fetch_wikidata_details(wikidata_q)
    return nil unless details

    # Search for the original result to get the label
    client = SubjectHeadings::WikidataClient.new
    results = client.search(@query, count: 20)
    result = results.find { |r| r[:entity_id] == "Q#{wikidata_q}" }

    name = result ? result[:label] : "Q#{wikidata_q}"
    dates = format_wikidata_dates(details[:birth_date], details[:death_date])

    person = Person.create!(
      name: name,
      dates: dates,
      country: details[:country],
      wikidata_q: wikidata_q.to_i
    )

    # Enrich with cross-authority IDs
    person.update(viaf_id: details[:authority_ids][:viaf].to_i) if details[:authority_ids][:viaf].present?
    person.update(loc_id: details[:authority_ids][:loc]) if details[:authority_ids][:loc].present?

    person
  rescue StandardError => e
    Rails.logger.error "Error creating person from Wikidata Q#{wikidata_q}: #{e.message}"
    nil
  end

  def create_person_from_loc(loc_id)
    # Search for more info
    client = LibraryOfCongress::NameAuthorityClient.new
    results = client.search_person(@query)
    result = results.find { |r| r[:loc_id] == loc_id }

    return nil unless result

    Person.create!(
      name: result[:label],
      dates: extract_dates_from_label(result[:label]),
      loc_id: loc_id
    )
  rescue StandardError => e
    Rails.logger.error "Error creating person from LoC #{loc_id}: #{e.message}"
    nil
  end

  def format_wikidata_dates(birth_date, death_date)
    return nil if birth_date.nil? && death_date.nil?

    birth_year = birth_date ? birth_date[0..3] : nil
    death_year = death_date ? death_date[0..3] : 'present'

    if birth_year && death_year
      "#{birth_year}-#{death_year}"
    elsif birth_year
      "#{birth_year}-"
    else
      nil
    end
  end

  # Helper to extract labels from Wikidata claims
  def extract_claim_labels(claims, client)
    return [] unless claims&.any?

    entity_ids = claims.map { |claim| claim.dig('mainsnak', 'datavalue', 'value', 'id') }.compact
    return [] if entity_ids.empty?

    labels = client.send(:fetch_labels, entity_ids)
    entity_ids.map { |id| labels[id] }.compact
  end

  # Helper to extract string value from Wikidata claim
  def extract_string_claim(claims)
    claims&.first&.dig('mainsnak', 'datavalue', 'value')
  end

  # Helper to extract time value from Wikidata claim
  def extract_time_claim(claims)
    time_value = claims&.first&.dig('mainsnak', 'datavalue', 'value', 'time')
    return nil unless time_value

    # Format: "+1952-03-11T00:00:00Z" -> "1952-03-11"
    time_value.gsub(/^\+/, '').split('T').first
  end

  # Association methods
  def associate_with_toc(person, toc_id)
    toc = Toc.find_by(id: toc_id)
    return false unless toc

    # Create association if it doesn't exist
    PeopleToc.find_or_create_by(person: person, toc: toc)
    true
  rescue StandardError => e
    Rails.logger.error "Error associating person #{person.id} with toc #{toc_id}: #{e.message}"
    false
  end

  def associate_with_work(person, work_id)
    work = Work.find_by(id: work_id)
    return false unless work

    # Create association if it doesn't exist
    PeopleWork.find_or_create_by(person: person, work: work)
    true
  rescue StandardError => e
    Rails.logger.error "Error associating person #{person.id} with work #{work_id}: #{e.message}"
    false
  end

  def associate_with_expression(person, expression_id)
    expression = Expression.find_by(id: expression_id)
    return false unless expression

    # Create association (realizer)
    Realization.find_or_create_by(realizer: person, expression: expression)
    true
  rescue StandardError => e
    Rails.logger.error "Error associating person #{person.id} with expression #{expression_id}: #{e.message}"
    false
  end
end
