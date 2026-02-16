class DropDeadSaasTables < ActiveRecord::Migration[6.0]
  def up
    # Payments/Subscriptions
    drop_table :subscriptions, if_exists: true
    drop_table :subscription_plan_variants, if_exists: true
    drop_table :subscription_plans, if_exists: true
    drop_table :payments, if_exists: true

    # Content/Marketing
    drop_table :articles, if_exists: true
    drop_table :authors, if_exists: true

    # Email campaigns (Caffeinate)
    drop_table :caffeinate_campaign_subscriptions, if_exists: true
    drop_table :caffeinate_mailings, if_exists: true
    drop_table :caffeinate_campaigns, if_exists: true

    # Analytics (Ahoy)
    drop_table :ahoy_clicks, if_exists: true
    drop_table :ahoy_messages, if_exists: true
    drop_table :ahoy_opens, if_exists: true

    # Dead user features
    drop_table :affiliates, if_exists: true
    drop_table :portfolio_assets, if_exists: true
    drop_table :portfolios, if_exists: true
    drop_table :surveys, if_exists: true
    drop_table :cards, if_exists: true

    # Misc
    drop_table :countries, if_exists: true
    drop_table :conversion_rates, if_exists: true
  end
end
