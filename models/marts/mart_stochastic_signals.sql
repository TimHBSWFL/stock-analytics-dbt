{{ config(materialized='table') }}

with source_data as (
    select *
    from {{ ref('stg_stock_prices') }}
),

rolling_range as (
    select
        ticker,
        trade_date,
        close,

        max(high) over (
            partition by ticker
            order by trade_date
            rows between 13 preceding and current row
        ) as rolling_high_14,

        min(low) over (
            partition by ticker
            order by trade_date
            rows between 13 preceding and current row
        ) as rolling_low_14,

        row_number() over (
            partition by ticker
            order by trade_date
        ) as day_num

    from source_data
),

k_raw as (
    select
        ticker,
        trade_date,
        close,
        day_num,
        case
            -- match pandas rolling(14): no value until a full 14-day window exists
            when day_num >= 14
            then 100 * (close - rolling_low_14) / nullif(rolling_high_14 - rolling_low_14, 0)
        end as k_raw
    from rolling_range
),

k_smoothed as (
    select
        ticker,
        trade_date,
        close,
        day_num,
        case
            when day_num >= 16
            then avg(k_raw) over (
                partition by ticker
                order by trade_date
                rows between 2 preceding and current row
            )
        end as stoch_k
    from k_raw
),

d_line as (
    select
        ticker,
        trade_date,
        close,
        stoch_k,
        case
            when day_num >= 18
            then avg(stoch_k) over (
                partition by ticker
                order by trade_date
                rows between 2 preceding and current row
            )
        end as stoch_d
    from k_smoothed
),

crossovers as (
    select
        ticker,
        trade_date,
        close,
        stoch_k,
        stoch_d,

        lag(stoch_k) over (
            partition by ticker
            order by trade_date
        ) as prev_stoch_k,

        lag(stoch_d) over (
            partition by ticker
            order by trade_date
        ) as prev_stoch_d

    from d_line
)

-- bullish crossover: %K crosses above %D while in oversold territory (< 20)
select
    ticker,
    trade_date,
    close,
    round(stoch_k, 2) as stoch_k,
    round(stoch_d, 2) as stoch_d
from crossovers
where prev_stoch_k < prev_stoch_d
    and stoch_k >= stoch_d
    and stoch_d < 20
