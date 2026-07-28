{{ config(materialized='table') }}

with source_data as (
    select *
    from {{ ref('int_daily_metrics')}}
),

base as (
    select
        ticker,
        trade_date,
        close,
        ma_10,
        ma_50,
        round((ma_10 - ma_50) / ma_50 * 100, 4) as ma_spread,

        lag(ma_10) over (
            partition by ticker
            order by trade_date
        ) as prev_ma_10,

        lag(ma_50) over (
            partition by ticker
            order by trade_date
        ) as prev_ma_50

    from source_data
),

golden_cross as (
    select *
    from base
    where prev_ma_10 < prev_ma_50
    and ma_10 >= ma_50
)

select *
from golden_cross