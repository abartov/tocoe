require 'openlibrary' # TODO: figure out how to search with the RESTful API, then ditch this

class PublicationsController < ApplicationController
  @@olclient = Openlibrary::Client.new
  def search
    unless params[:search].blank?
      @results = PublicationsController.olclient.search(params[:search])
      unless @results.blank?
        @results.each {|r| logger.info "#{r.title} / #{r.author_name} #{r.has_fulltext ? "[ebook!]" : "metadata only"}"}
      end
    end
  end

  def details
    @olkey = params[:olkey]
  end

  def browse
  end

  def savetoc
  end
  def self.olclient
    @@olclient
  end
end
