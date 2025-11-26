# Manifestation
class ManifestationsController < ApplicationController
  def show
    @manifestation = Manifestation.find(params[:id])
  end

  def approve
  end
end
