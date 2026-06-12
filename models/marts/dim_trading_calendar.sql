with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2025-01-01' as date)",
        end_date="cast(current_date() as date)"
    )}}
),

trading_dates as (
    select distinct trade_date
    from {{ ref('stg_stock_prices') }}
),

merged as (
    select
        cast(d.date_day as date) as date_day,
        date_format(d.date_day, 'EEEE') as day_of_week, -- returns 'Monday', 'Saturday', etc.
        case when dayofweek(d.date_day) in (1, 7) then 1 else 0 end as is_weekend,
        case when t.trade_date is not null then 1 else 0 end as is_trading_day
    from date_spine d
    left join trading_dates t
        on d.date_day = t.trade_date
)

select *
from merged