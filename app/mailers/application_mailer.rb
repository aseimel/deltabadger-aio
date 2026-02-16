class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('NOTIFICATIONS_SENDER')
  layout 'mailers/transactional'

  def default_url_options
    {}
  end
end
