with base as (
    select
        ticker,
        trade_date,
        close,
        lag(close) over (
            partition by ticker
            order by trade_date
        ) as prev_close,

        avg(close) over (
            partition by ticker
            order by trade_date
            rows between 9 preceding and current row
        ) as ma_10,

        avg(close) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) as ma_20,

        avg(close) over (
            partition by ticker
            order by trade_date
            rows between 49 preceding and current row
        ) as ma_50

    from {{ ref('stg_stock_prices')}}

)

select
    ticker,
    trade_date,
    close,
    (close - prev_close) / nullif(prev_close, 0) as daily_return,
    ma_10,
    ma_20,
    ma_50
from base