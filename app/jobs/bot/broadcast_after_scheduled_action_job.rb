class Bot::BroadcastAfterScheduledActionJob < ApplicationJob
  queue_as :default

  def perform(bot)
    # This loop makes sure sidekiq has time to schedule the job
    success = false
    50.times do
      if bot.next_action_job_at.present?
        success = true
        break
      end

      sleep 0.1
    end

    unless success
      Rails.logger.warn("BroadcastAfterScheduledActionJob: next_action_job_at not set after 5s for bot #{bot.id}")
    end

    bot.broadcast_status_bar_update
  end
end
