select
    ticker,
    trade_date,
    count(*) as row_count
from {{ ref('mart_stock_features')}}
group by ticker, trade_date
having count(*) > 1

