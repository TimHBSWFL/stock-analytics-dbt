{{ config(store_failures = true) }}

select
    trade_date,
    count(distinct ticker) as ticker_count
from {{ ref('stg_stock_prices') }}
where trade_date >= dateadd(day, -3, current_date())
group by trade_date
having count(distinct ticker) < {{ var('expected_ticker_count', 40) }}