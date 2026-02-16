class MakeWithdrawalWorker
  include Sidekiq::Worker

  def perform(bot_id)
    MakeWithdrawal.call(bot_id)
    bot = Bot.find(bot_id)
    bot.broadcast_status_bar_update
  rescue StandardError => e
    Rails.logger.error("[MakeWithdrawalWorker] Bot #{bot_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
    bot = Bot.find(bot_id) rescue nil
    bot&.broadcast_status_bar_update
  end
end
