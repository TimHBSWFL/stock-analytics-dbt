select
    ticker,
    trade_date,
    open,
    high,
    low,
    close,
    volume
from {{ source('analytics', 'stock_prices')}}