select *
from {{ ref('mart_stock_features') }}
where close <= 0