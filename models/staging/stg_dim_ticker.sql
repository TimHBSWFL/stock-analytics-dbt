select
    ticker,
    company_name,
    sector,
    industry
from {{ source('analytics', 'dim_ticker')}}