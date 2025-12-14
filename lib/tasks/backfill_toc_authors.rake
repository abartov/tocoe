namespace :toc do
  desc "Backfill author data for existing TOCs"
  task backfill_authors: :environment do
    puts "Backfilling author data for TOCs..."

    tocs_updated = 0
    tocs_failed = 0

    Toc.includes(:authors).find_each do |toc|
      # Skip if already has authors
      if toc.authors.any?
        puts "  [SKIP] #{toc.title} - already has authors"
        next
      end

      begin
        # Determine source and fetch author data
        if toc.source == 'gutenberg' && toc.book_uri =~ %r{gutenberg\.org/ebooks/(\d+)}
          pg_book_id = $1
          gutendex_client = Gutendex::Client.new
          book_data = gutendex_client.book(pg_book_id)

          authors = book_data['authors'] || []
          if authors.any?
            authors.each do |author_data|
              # Find or create Person
              person = Person.find_by(name: author_data['name'])
              if person.nil?
                person = Person.create!(name: author_data['name'])
              end

              # Create PeopleToc association
              PeopleToc.find_or_create_by!(person: person, toc: toc)
            end

            tocs_updated += 1
            puts "  [OK] #{toc.title} - added #{authors.count} author(s)"
          else
            puts "  [SKIP] #{toc.title} - no authors in API response"
          end

        elsif toc.source == 'openlibrary' || toc.book_uri =~ %r{openlibrary\.org/books/([A-Z0-9]+)}i
          ol_book_id = $1
          ol_client = OpenLibrary::Client.new
          book_uri = "http://openlibrary.org/books/#{ol_book_id}"

          # Fetch book data
          book_data = HTTParty.get("#{book_uri}.json", timeout: 10)
          unless book_data.success?
            puts "  [ERROR] #{toc.title} - failed to fetch book data: #{book_data.code}"
            tocs_failed += 1
            next
          end

          book = JSON.parse(book_data.body)
          author_keys = (book['authors'] || []).collect { |a| a['key'] }

          if author_keys.any?
            author_keys.each do |author_key|
              # Fetch author data
              author_response = HTTParty.get("http://openlibrary.org#{author_key}.json", timeout: 10)
              unless author_response.success?
                puts "  [WARN] #{toc.title} - failed to fetch author #{author_key}"
                next
              end

              author_data = JSON.parse(author_response.body)

              # Find or create Person by openlibrary_id
              person = Person.find_by_openlibrary_id(author_key)
              if person.nil?
                person = Person.create!(openlibrary_id: author_key, name: author_data['name'])
              end

              # Create PeopleToc association
              PeopleToc.find_or_create_by!(person: person, toc: toc)
            end

            tocs_updated += 1
            puts "  [OK] #{toc.title} - added #{author_keys.count} author(s)"
          else
            puts "  [SKIP] #{toc.title} - no authors in API response"
          end

        else
          puts "  [SKIP] #{toc.title} - unknown source"
        end

      rescue => e
        tocs_failed += 1
        puts "  [ERROR] #{toc.title} - #{e.class}: #{e.message}"
      end
    end

    puts "\nBackfill complete:"
    puts "  TOCs updated: #{tocs_updated}"
    puts "  TOCs failed: #{tocs_failed}"
  end
end
