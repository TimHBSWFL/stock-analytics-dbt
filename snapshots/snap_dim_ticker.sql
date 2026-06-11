{% snapshot snap_dim_ticker %}

    {{ config(
        target_schema='analytics',
        unique_key='ticker',
        strategy='check',
        check_cols=['company_name', 'sector', 'industry']
    )
    }}

    select * from {{ source('analytics', 'dim_ticker')}}

{% endsnapshot %}