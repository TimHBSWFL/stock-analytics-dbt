{{ config(materialized='table') }}

with source_data as (
    select *
    from {{ ref('stg_stock_prices') }}
),

daily_changes as (
    select
        ticker,
        trade_date,
        close,
        close - lag(close) over (
            partition by ticker
            order by trade_date
        ) as daily_change
    from source_data
),

gains_losses as (
    select
        ticker,
        trade_date,
        close,
        daily_change,
        case
            when daily_change > 0 then daily_change
            else 0
        end as gain,

        case
            when daily_change < 0 then abs(daily_change)
            else 0
        end as loss
    from daily_changes
),

rsi_calc as (
    select
        ticker,
        trade_date,
        close,

        avg(gain) over (
            partition by ticker
            order by trade_date
            rows between 13 preceding and current row
        ) as avg_gain_14,

        avg(loss) over (
            partition by ticker
            order by trade_date
            rows between 13 preceding and current row
        ) as avg_loss_14
    from gains_losses
),

rsi as (
    select
        ticker,
        trade_date,
        close,
        avg_gain_14,
        avg_loss_14,
        case
            when avg_loss_14 = 0 then 100
            else round(100 - (100 / (1 + avg_gain_14 / avg_loss_14)), 2)
        end as rsi_14
    from rsi_calc

)

select
    ticker,
    trade_date,
    close,
    rsi_14
from rsi
where rsi_14 < 30