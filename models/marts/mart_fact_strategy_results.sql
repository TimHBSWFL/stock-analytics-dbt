with trades as (
    select
        s.ticker,
        s.trade_date as entry_date,
        s.close as entry_price,

        lead(f.trade_date, 5) over (
            partition by f.ticker
            order by f.trade_date
        ) as exit_date,

        lead(f.close, 5) over (
            partition by f.ticker
            order by f.trade_date
        ) as exit_price

    from {{ ref('mart_daily_stock_screener')}} s
    join {{ ref('stg_stock_prices')}} f
        on s.ticker = f.ticker
        and s.trade_date = f.trade_date
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
where exit_price is not null