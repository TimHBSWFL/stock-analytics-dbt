{% macro incremental_lookback_filter(date_column, lookback_days) %}
    {% if is_incremental() %}
    where {{ date_column }} >= (
        select dateadd(day, -{{ lookback_days }}, max({{ date_column }}))
        from {{ this }}
    )
    {% endif %}
{% endmacro %}