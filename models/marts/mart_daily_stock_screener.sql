with latest_data as (
    select *
    from {{ ref('mart_stock_features')}}
    where trade_date = (
        select max(trade_date)
        from {{ ref('mart_stock_features')}}
    )
),

filtered as (
    select *
    from latest_data
    where
        is_breakout_candidate = 1
        and return_20d > 0.05
        and is_volume_spike = 1
        and vol_20d < 0.5
        and pct_of_20d_high >= 0.99
)

select
    ticker,
    trade_date,
    close,
    volume,

    return_5d,
    return_20d,
    return_50d,

    vol_20d,
    avg_volume_20d,
    pct_of_20d_high,
    momentum_rank,

    current_timestamp() as created_at
from filtered
order by return_20d desc