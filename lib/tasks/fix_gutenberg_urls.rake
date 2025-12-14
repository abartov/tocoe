# Rake task to fix HTTP Gutenberg URLs to HTTPS
# This prevents mixed content warnings in production
#
# Usage:
#   rake toc:fix_gutenberg_urls          # Fix all HTTP Gutenberg URLs
#   rake toc:fix_gutenberg_urls[dry_run] # Dry run - show what would be changed

namespace :toc do
  desc 'Fix HTTP Gutenberg URLs to HTTPS in TOC records'
  task :fix_gutenberg_urls, [:mode] => :environment do |_t, args|
    dry_run = args[:mode] == 'dry_run'

    if dry_run
      puts "DRY RUN MODE - No changes will be made"
      puts "=" * 80
    end

    # Fix book_uri field
    http_book_uris = Toc.where("book_uri LIKE ?", "http://%.gutenberg.org%")

    puts "\nChecking book_uri field..."
    puts "Found #{http_book_uris.count} TOC(s) with HTTP Gutenberg book URIs"

    if http_book_uris.any?
      http_book_uris.each do |toc|
        old_uri = toc.book_uri
        new_uri = old_uri.sub(/\Ahttp:/, 'https:')

        puts "  TOC ##{toc.id}: #{old_uri} -> #{new_uri}"

        unless dry_run
          toc.update_column(:book_uri, new_uri)
        end
      end

      unless dry_run
        puts "✓ Updated #{http_book_uris.count} book_uri(s)"
      end
    else
      puts "  No HTTP Gutenberg URIs found in book_uri field"
    end

    # Fix toc_page_urls field (contains newline-separated URLs)
    tocs_with_page_urls = Toc.where("toc_page_urls LIKE ?", "%http://%.gutenberg.org%")

    puts "\nChecking toc_page_urls field..."
    puts "Found #{tocs_with_page_urls.count} TOC(s) with HTTP Gutenberg page URLs"

    if tocs_with_page_urls.any?
      tocs_with_page_urls.each do |toc|
        old_urls = toc.toc_page_urls
        new_urls = old_urls.gsub(/http:\/\/([^\s]*\.)?gutenberg\.org/, 'https://\1gutenberg.org')

        if old_urls != new_urls
          puts "  TOC ##{toc.id}: Updated #{toc.toc_page_urls.split("\n").count} page URL(s)"

          unless dry_run
            toc.update_column(:toc_page_urls, new_urls)
          end
        end
      end

      unless dry_run
        puts "✓ Updated #{tocs_with_page_urls.count} toc_page_urls record(s)"
      end
    else
      puts "  No HTTP Gutenberg URIs found in toc_page_urls field"
    end

    # Fix book_data field (JSON field that might contain Gutenberg URLs)
    tocs_with_book_data = Toc.where("book_data LIKE ?", "%http://%.gutenberg.org%")

    puts "\nChecking book_data field..."
    puts "Found #{tocs_with_book_data.count} TOC(s) with HTTP Gutenberg URLs in book_data"

    if tocs_with_book_data.any?
      tocs_with_book_data.each do |toc|
        old_data = toc.book_data
        new_data = old_data.gsub(/http:\/\/([^\s"]*\.)?gutenberg\.org/, 'https://\1gutenberg.org')

        if old_data != new_data
          puts "  TOC ##{toc.id}: Updated book_data JSON"

          unless dry_run
            toc.update_column(:book_data, new_data)
          end
        end
      end

      unless dry_run
        puts "✓ Updated #{tocs_with_book_data.count} book_data record(s)"
      end
    else
      puts "  No HTTP Gutenberg URIs found in book_data field"
    end

    puts "\n" + "=" * 80
    if dry_run
      puts "DRY RUN COMPLETE - Run without 'dry_run' argument to apply changes"
    else
      puts "✓ COMPLETE - All HTTP Gutenberg URLs have been updated to HTTPS"
    end
  end
end
