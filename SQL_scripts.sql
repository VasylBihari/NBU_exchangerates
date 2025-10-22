CREATE OR REPLACE VIEW table_courses AS
SELECT * FROM nbu_exchange_rates

CREATE OR REPLACE VIEW eur_usd_other AS
WITH rates AS (
    SELECT 
        date,
        currency_code,
        currency_name,
        rate,
        ROW_NUMBER() OVER (PARTITION BY currency_code ORDER BY date DESC) AS rn
    FROM nbu_exchange_rates
)
, latest AS (
    SELECT currency_code, currency_name, rate AS latest_rate
    FROM rates
    WHERE rn = 1
)
, previous AS (
    SELECT currency_code, rate AS prev_rate
    FROM rates
    WHERE rn = 2
)
SELECT 
    l.currency_code,
    l.currency_name,
    l.latest_rate,
    p.prev_rate,
    CASE 
        WHEN l.latest_rate > p.prev_rate 
            THEN '▲ +' || ROUND(l.latest_rate - p.prev_rate, 2)::text 
                 || ' (' || ROUND(((l.latest_rate - p.prev_rate) / p.prev_rate) * 100, 2)::text || '%)'
        WHEN l.latest_rate < p.prev_rate 
            THEN '▼ ' || ROUND(l.latest_rate - p.prev_rate, 2)::text 
                 || ' (' || ROUND(((l.latest_rate - p.prev_rate) / p.prev_rate) * 100, 2)::text || '%)'
        ELSE '0.00 (0.00%)'
    END AS change_label,
    CASE 
        WHEN l.currency_code IN ('USD','EUR') THEN 'MAIN'
        ELSE 'OTHER'
    END AS category
FROM latest l
JOIN previous p 
  ON l.currency_code = p.currency_code;


CREATE OR REPLACE VIEW avg_month AS
SELECT DATE_TRUNC('month', date) AS month, currency_code, ROUND(AVG(rate),3) AS avg_rate
FROM nbu_exchange_rates
GROUP BY month, currency_code
ORDER BY month;

CREATE OR REPLACE VIEW top_five AS
SELECT currency_code, MAX(rate) AS max_rate
FROM nbu_exchange_rates
GROUP BY currency_code
ORDER BY max_rate DESC
LIMIT 5;

CREATE OR REPLACE VIEW button_five AS
SELECT currency_code, MIN(rate) AS min_rate
FROM nbu_exchange_rates
GROUP BY currency_code
ORDER BY min_rate ASC
LIMIT 5;

CREATE OR REPLACE VIEW volatility_five AS
SELECT currency_code, ROUND(STDDEV(rate),4) AS volatility
FROM nbu_exchange_rates
GROUP BY currency_code
ORDER BY volatility DESC
LIMIT 5;

CREATE OR REPLACE VIEW change_currency AS
WITH base_rates AS (
    SELECT
        currency_code,
        rate AS base_rate
    FROM nbu_exchange_rates
    WHERE date = '2025-01-01'
    GROUP BY currency_code, rate
)
SELECT DISTINCT
    e.date,
    e.currency_code,
    e.rate,
    ROUND(((e.rate - b.base_rate) / b.base_rate) * 100, 2) AS rate_change_pct
FROM nbu_exchange_rates e
JOIN base_rates b ON e.currency_code = b.currency_code
WHERE e.date >= '2025-01-01'
ORDER BY e.date, e.currency_code;



