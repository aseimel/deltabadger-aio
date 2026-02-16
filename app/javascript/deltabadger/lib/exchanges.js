export const exchanges = {
  'binance': {
      name: 'Binance',
      url: 'https://www.binance.com/en/register?ref=NUYVIP6R',
      translation_key: 'binance',
  },
  'binance.us': {
      name: 'Binance.US',
      url: 'https://www.binance.us/en/home',
      translation_key: 'binance',
  },
  'zonda': {
      name: 'Zonda',
      url: 'https://zondacrypto.com/',
      translation_key: 'zonda',
  },
  'kraken': {
      name: 'Kraken',
      url: 'https://r.kraken.com/deltabadger',
      translation_key: 'kraken',
  },
  'coinbase': {
      name: 'Coinbase',
      url: 'https://www.coinbase.com/advanced-trade',
      translation_key: 'coinbase',
  },
  'gemini': {
      name: 'Gemini',
      url: 'https://exchange.gemini.com/signin',
      translation_key: 'gemini',
  },
  'bitso': {
    name: 'Bitso',
    url: 'https://bitso.com/',
    translation_key: 'bitso'
  },
  'kucoin': {
    name: 'KuCoin',
    url: 'https://kucoin.com/',
    translation_key: 'kucoin'
  },
  'bitfinex': {
    name: 'Bitfinex',
    url: 'https://bitfinex.com/',
    translation_key: 'bitfinex'
  },
  'bitstamp': {
    name: 'Bitstamp',
    url: 'https://bitstamp.net/',
    translation_key: 'bitstamp'
  },
  'bitget': {
    name: 'Bitget',
    url: 'https://www.bitget.com/',
    translation_key: 'bitget'
  },
  'bybit': {
    name: 'Bybit',
    url: 'https://www.bybit.com/',
    translation_key: 'bybit'
  },
  'mexc': {
    name: 'MEXC',
    url: 'https://www.mexc.com/',
    translation_key: 'mexc'
  },
  'bitvavo': {
    name: 'Bitvavo',
    url: 'https://bitvavo.com/',
    translation_key: 'bitvavo'
  },
}

export const getExchange = (exchangeName, type) => {
  let exchange = {...exchanges[exchangeName.toLowerCase()]}
  if (type === 'withdrawal' || type === 'withdrawal_address') {
    exchange.translation_key = type + '.' + exchange.translation_key
  }

  return exchange
}
