with reference_day as (
    select ticker
    from {{ ref('stg_stock_prices') }}
    where trade_date = (
        select max(trade_date)
        from {{ ref('stg_stock_prices') }}
        where trade_date < '2026-06-15'
    )
),

problem_day as (
    select ticker
    from {{ ref('stg_stock_prices') }}
    where trade_date = '2026-06-15'
)

select r.ticker
from reference_day r
left join problem_day p
    on r.ticker = p.ticker
where p.ticker is null