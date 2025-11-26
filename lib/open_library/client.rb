# based on this code by @tylercrocker - https://github.com/jayfajardo/openlibrary/issues/36#issuecomment-1087102052
# further adapted to our needs by Asaf Bartov @abartov

class OpenLibrary::Client
  API_URL = 'https://openlibrary.org'

  def initialize
  end

  def request(the_path)
    path = the_path.include?('.json') ? the_path : "#{the_path}.json"
    resp = Net::HTTP.get_response(URI.parse("#{API_URL}#{path}"))
    raise 'FAILED' unless resp.code == '200'

    JSON.parse(resp.body)
  end

  def author olid
    request("/authors/#{olid}")
  end

  def work olid
    request("/works/#{olid}")
  end

  def book olid
    request("/books/#{olid}")
  end

  def search query: nil, author: nil, title: nil, has_fulltext: false
    q = []
    q << "q=#{CGI.escape(query)}" unless query.blank?
    q << "author=#{CGI.escape(author)}" unless author.blank?
    q << "title=#{CGI.escape(title)}" unless title.blank?
    q << "has_fulltext=true" if has_fulltext
    # Request edition information including key, language, and ebook_access
    q << "fields=*,editions,editions.key,editions.language,editions.ebook_access"
    request("/search.json?#{q.join('&')}")
  end
end