require 'openlibrary'

class WorksController < ApplicationController
  @@olclient = Openlibrary::Client.new
  def search
    unless params[:search].blank?
      @results = WorksController.olclient.search(params[:search])
      unless @results.blank?
        logger.info "#{@results.length} results found:"
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
