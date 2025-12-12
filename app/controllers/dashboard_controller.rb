class DashboardController < ApplicationController
  def index
    # User's recent TOCs
    @my_tocs = Toc.where(contributor: current_user)
                  .order(updated_at: :desc)
                  .limit(5)

    # TOCs needing verification (transcribed, not by current user)
    @needs_verification = Toc.where(status: :transcribed)
                             .where.not(contributor: current_user)
                             .order(updated_at: :desc)
                             .limit(5)

    # Global project statistics
    @stats = {
      total: Toc.count,
      verified: Toc.where(status: :verified).count,
      needs_work: Toc.where.not(status: :verified).count,
      contributors: User.count
    }

    # Current user's contribution statistics
    @my_contribution_stats = {
      total: current_user.tocs.count,
      verified: current_user.tocs.where(status: :verified).count,
      in_progress: current_user.tocs.where.not(status: :verified).count
    }

    # Recent community activity (recent verifications)
    @recent_community_activity = Toc.where(status: :verified)
                                    .where.not(verified_at: nil)
                                    .order(verified_at: :desc)
                                    .limit(10)
                                    .includes(:reviewer, :contributor)
  end

  def aboutness
    # Find verified TOCs with embodiments that have no aboutnesses
    @tocs_needing_subjects = Toc.where(status: :verified)
                                .joins(manifestation: { embodiments: :expression })
                                .left_joins(manifestation: { embodiments: :aboutnesses })
                                .where(aboutnesses: { id: nil })
                                .distinct
                                .order(updated_at: :desc)
                                .includes(manifestation: { embodiments: [:expression, :aboutnesses] })
  end
end
