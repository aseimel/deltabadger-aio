class DropDeadSaasTables < ActiveRecord::Migration[6.0]
  def up
    # Drop foreign keys from active tables that reference dead tables
    execute <<-SQL
      DO $$
      DECLARE r RECORD;
      BEGIN
        FOR r IN (
          SELECT conname, conrelid::regclass AS table_name
          FROM pg_constraint
          WHERE confrelid IN (
            'subscriptions'::regclass,
            'subscription_plans'::regclass,
            'subscription_plan_variants'::regclass,
            'payments'::regclass
          )
          AND contype = 'f'
        ) LOOP
          EXECUTE 'ALTER TABLE ' || r.table_name || ' DROP CONSTRAINT ' || r.conname;
        END LOOP;
      EXCEPTION WHEN undefined_table THEN
        NULL;
      END $$;
    SQL

    # Drop all dead SaaS tables with CASCADE for any remaining dependencies
    tables = %w[
      subscriptions subscription_plan_variants subscription_plans payments
      articles authors
      caffeinate_campaign_subscriptions caffeinate_mailings caffeinate_campaigns
      ahoy_clicks ahoy_messages ahoy_opens
      affiliates portfolio_assets portfolios surveys cards
      countries conversion_rates
    ]

    tables.each do |table|
      execute "DROP TABLE IF EXISTS #{table} CASCADE"
    end
  end
end
