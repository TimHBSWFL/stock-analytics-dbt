{% macro percent_change_calculation(close, prev_close) %}
    ({{ close }} - {{ prev_close }}) / nullif({{ prev_close }}, 0)
{% endmacro %}