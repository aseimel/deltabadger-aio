class Bot::BroadcastPnlUpdateJob < ApplicationJob
  queue_as :default

  def perform(bot)
    bot.broadcast_pnl_update
  rescue => e
    Rails.logger.error("[BroadcastPnlUpdateJob] Bot #{bot.id}: #{e.class} - #{e.message}")
    bot.broadcast_replace_to(
      ["user_#{bot.user_id}", :bot_updates],
      target: ActionView::RecordIdentifier.dom_id(bot, :pnl),
      partial: "bots/bot_tile/bot_tile_pnl",
      locals: { bot: bot, pnl: "", loading: false }
    )
  end
end
