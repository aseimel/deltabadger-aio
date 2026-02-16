class Bots::Withdrawal < Bot
  include LegacyMethods
  include Schedulable

  def api_key_type
    :withdrawal
  end

  def restarting?
    false
    # restart_params = GetRestartParams.call(bot_id: id)
    # restart_params[:restartType] == 'missed'
  end

  def restarting_within_interval?
    false
    # restart_params = GetRestartParams.call(bot_id: id)
    # restart_params[:restartType] == 'onSchedule'
  end

  def missed_amount
    0
    # restart_params = GetRestartParams.call(bot_id: id)
    # restart_params[:missedAmount]
  end

  def start(start_fresh: true)
    self.status = :scheduled
    self.stop_message_key = nil
    self.started_at = Time.current if start_fresh

    if save
      ScheduleWithdrawal.new.call(self, first_transaction: true)
      true
    else
      false
    end
  end

  def stop(stop_message_key: nil)
    if update(status: :stopped, stopped_at: Time.current, stop_message_key: stop_message_key)
      cancel_scheduled_action_jobs
      true
    else
      false
    end
  end

  def delete
    if update(status: :deleted, stopped_at: Time.current)
      cancel_scheduled_action_jobs
      true
    else
      false
    end
  end

  private

  def action_job_config
    {
      queue: exchange.name.downcase,
      class: 'MakeWithdrawalWorker',
      args: [id]
    }
  end
end
