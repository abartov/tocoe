json.array!(@tocs) do |toc|
  json.extract! toc, :id, :book_uri, :toc_body, :status, :contributor_id, :reviewer_id, :comments
  json.url toc_url(toc, format: :json)
end
