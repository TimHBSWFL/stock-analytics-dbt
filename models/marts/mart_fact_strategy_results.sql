with all_prices as (
    select
        ticker,
        trade_date,
        close,
        row_number() over (partition by ticker order by trade_date) as day_num
    from {{ ref('stg_stock_prices') }}
),

screener_entries as (
    select
        ticker,
        trade_date as entry_date,
        close as entry_price
    from {{ ref('mart_historical_screener') }}
),

entry_with_day_num as (
    select
        s.ticker,
        s.entry_date,
        s.entry_price,
        p.day_num as entry_day_num
    from screener_entries s
    join all_prices p
        on s.ticker = p.ticker
        and s.entry_date = p.trade_date
),

trades as (
    select
        e.ticker,
        e.entry_date,
        e.entry_price,
        x.trade_date as exit_date,
        x.close as exit_price
    from entry_with_day_num e
    join all_prices x
        on e.ticker = x.ticker
        and x.day_num = e.entry_day_num + 5
)

select
    ticker,
    entry_date,
    exit_date,
    entry_price,
    exit_price,
    (exit_price - entry_price) / entry_price as return_pct,
    5 as holding_days,
    case
        when exit_price > entry_price then 1
        else 0
    end as is_winner,
    current_timestamp() as created_at
from trades
