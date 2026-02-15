class AddNewExchanges < ActiveRecord::Migration[6.0]
  def up
    # Use raw SQL to ensure this works during container initialization
    # Check and insert Bitget
    execute <<-SQL
      INSERT INTO exchanges (name, type, maker_fee, taker_fee, withdrawal_fee, created_at, updated_at)
      SELECT 'Bitget', 'Exchanges::Bitget', 0.1, 0.1, 0.0004, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE type = 'Exchanges::Bitget');
    SQL

    # Check and insert Bybit
    execute <<-SQL
      INSERT INTO exchanges (name, type, maker_fee, taker_fee, withdrawal_fee, created_at, updated_at)
      SELECT 'Bybit', 'Exchanges::Bybit', 0.1, 0.1, 0.0002, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE type = 'Exchanges::Bybit');
    SQL

    # Check and insert MEXC
    execute <<-SQL
      INSERT INTO exchanges (name, type, maker_fee, taker_fee, withdrawal_fee, created_at, updated_at)
      SELECT 'MEXC', 'Exchanges::Mexc', 0.0, 0.05, 0.0005, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE type = 'Exchanges::Mexc');
    SQL

    # Check and insert Bitvavo
    execute <<-SQL
      INSERT INTO exchanges (name, type, maker_fee, taker_fee, withdrawal_fee, created_at, updated_at)
      SELECT 'Bitvavo', 'Exchanges::Bitvavo', 0.15, 0.25, 0.0, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE type = 'Exchanges::Bitvavo');
    SQL
  end

  def down
    execute "DELETE FROM exchanges WHERE type IN ('Exchanges::Bitget', 'Exchanges::Bybit', 'Exchanges::Mexc', 'Exchanges::Bitvavo');"
  end
end
