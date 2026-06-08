with base as (
    select *
    from {{ ref('mart_stock_features') }}
    where 
        is_breakout_candidate = 1
        and return_20d > 0.05
        and is_volume_spike = 1
        and vol_20d < 0.5
        and pct_of_20d_high >= 0.99
),

sectors as (
    select *
    from {{ ref('stg_dim_ticker')}}
),

merged as (
    select
        b.*,
        s.company_name,
        s.sector,
        s.industry
    from base b
    left join sectors s on b.ticker = s.ticker
)

select
    ticker,
    company_name,
    sector,
    industry,

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
from merged
order by trade_date desc, return_20d desc
