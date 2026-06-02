{{ config(materialized='incremental', unique_key=['ticker', 'trade_date']) }}

with source_data as (
    select *
    from {{ ref('stg_stock_prices') }}

    {% if is_incremental() %}

    where trade_date >= (
        select dateadd(day, -60, max(trade_date))
        from {{ this }}
    )
    {% endif %}
),

base as (
    select
        ticker,
        trade_date,
        close,
        volume,

        lag(close) over (
            partition by ticker
            order by trade_date
        ) as prev_close

    from source_data
),

returns as (
    select *,
        {{ percent_change_calculation('close', 'prev_close') }} as daily_return
    from base
    where prev_close is not null
),

rolling as (
    select *,
        (close / lag(close, 5) over (partition by ticker order by trade_date)) -1 as return_5d,
        (close / lag(close, 20) over (partition by ticker order by trade_date)) -1 as return_20d,
        (close / lag(close, 50) over (partition by ticker order by trade_date)) -1 as return_50d,

        stddev(daily_return) over (
            partition by ticker
            order by trade_date
            rows between 20 preceding and 1 preceding
        ) as vol_20d,

        avg(volume) over (
            partition by ticker
            order by trade_date
            rows between 20 preceding and 1 preceding
        ) as avg_volume_20d,

        max(close) over (
            partition by ticker
            order by trade_date
            rows between 20 preceding and 1 preceding
        ) as high_20d

    from returns
),

features as (
    select *,
        (close / high_20d) as pct_of_20d_high,

        case
            when volume > avg_volume_20d then 1 else 0
        end as is_volume_spike,

        case 
            when close >= high_20d * 0.99
                and return_20d > 0
                and volume > avg_volume_20d
            then 1 else 0
        end as is_breakout_candidate,

        row_number() over (
            partition by trade_date
            order by return_20d desc
        ) as momentum_rank

    from rolling
)

select *
from features
where return_50d is not null

{% if is_incremental() %}
and trade_date > (select max(trade_date) from {{ this }})
{% endif %}