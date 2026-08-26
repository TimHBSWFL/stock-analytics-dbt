{{ config(materialized='table') }}

with bollinger as (
    select
        ticker,
        trade_date,
        close,
        avg(close) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) as bb_middle,

        stddev(close) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) as bb_stddev
    from {{ ref('stg_stock_prices')}}
),

bands as (
    select
        ticker,
        trade_date,
        close,
        bb_middle,
        bb_middle - (2 * bb_stddev) as bb_lower
    from bollinger
),

macd as (
    select
        ticker,
        trade_date,
        macd_line,
        signal_line,
        histogram
    from {{ source('analytics', 'macd_signals') }}
)

select
    b.ticker,
    b.trade_date,
    b.close,
    b.bb_middle,
    b.bb_lower,
    m.macd_line,
    m.signal_line,
    m.histogram
from macd m
join bands b
    on m.ticker = b.ticker
    and m.trade_date = b.trade_date
where b.close <= b.bb_lower * 1.05