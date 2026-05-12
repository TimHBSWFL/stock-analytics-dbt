select
    ticker,
    trade_date,
    count(*) as row_count
from {{ ref('int_daily_metrics')}}
group by ticker, trade_date
having count(*) > 1