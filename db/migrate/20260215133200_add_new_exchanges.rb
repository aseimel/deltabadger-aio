class AddNewExchanges < ActiveRecord::Migration[6.0]
  def up
    # Add Bitget exchange
    bitget = Exchanges::Bitget.find_or_create_by!(name: 'Bitget')
    bitget.update!(maker_fee: '0.1', taker_fee: '0.1', withdrawal_fee: '0.0004')

    # Add Bybit exchange
    bybit = Exchanges::Bybit.find_or_create_by!(name: 'Bybit')
    bybit.update!(maker_fee: '0.1', taker_fee: '0.1', withdrawal_fee: '0.0002')

    # Add MEXC exchange
    mexc = Exchanges::Mexc.find_or_create_by!(name: 'MEXC')
    mexc.update!(maker_fee: '0.0', taker_fee: '0.05', withdrawal_fee: '0.0005')

    # Add Bitvavo exchange
    bitvavo = Exchanges::Bitvavo.find_or_create_by!(name: 'Bitvavo')
    bitvavo.update!(maker_fee: '0.15', taker_fee: '0.25', withdrawal_fee: '0.0')
  end

  def down
    # Remove the exchanges if rolling back
    Exchange.where(type: ['Exchanges::Bitget', 'Exchanges::Bybit', 'Exchanges::Mexc', 'Exchanges::Bitvavo']).destroy_all
  end
end
