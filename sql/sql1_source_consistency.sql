-- SQL 1: độ nhất quán giữa hai nguồn EIA-930 (chỉ 8 BA, UTC end-of-hour, dữ liệu thô, chưa làm sạch)
WITH p AS (
    SELECT ba, ts_utc, AVG(TRY_CAST(demand_raw AS DOUBLE)) AS demand_p
    FROM primary_src WHERE ba IN ('AZPS', 'BPAT', 'CISO', 'LDWP', 'NEVP', 'PACW', 'PGE', 'SRP') AND ts_utc IS NOT NULL GROUP BY ba, ts_utc),
s AS (
    SELECT ba, ts_utc, AVG(demand_secondary) AS demand_s
    FROM secondary_src WHERE ba IN ('AZPS', 'BPAT', 'CISO', 'LDWP', 'NEVP', 'PACW', 'PGE', 'SRP') AND ts_utc IS NOT NULL GROUP BY ba, ts_utc),
j AS (
    SELECT COALESCE(p.ba, s.ba)         AS ba,
           COALESCE(p.ts_utc, s.ts_utc) AS ts_utc,
           p.demand_p, s.demand_s,
           CASE WHEN p.ts_utc IS NOT NULL THEN 1 ELSE 0 END AS in_p,
           CASE WHEN s.ts_utc IS NOT NULL THEN 1 ELSE 0 END AS in_s,
           CASE WHEN p.demand_p IS NOT NULL AND s.demand_s IS NOT NULL THEN 1 ELSE 0 END AS comparable
    FROM p FULL OUTER JOIN s ON p.ba = s.ba AND p.ts_utc = s.ts_utc)
SELECT m.ba_name                                                        AS BA_Name,
       j.ba                                                             AS BA_Code,
       SUM(in_p)                                                        AS Primary_Rows,
       SUM(in_s)                                                        AS Secondary_Rows,
       SUM(CASE WHEN in_p = 1 AND in_s = 1 THEN 1 ELSE 0 END)           AS Matched_Rows,
       SUM(CASE WHEN in_p = 1 AND in_s = 0 THEN 1 ELSE 0 END)           AS Only_In_Primary,
       SUM(CASE WHEN in_p = 0 AND in_s = 1 THEN 1 ELSE 0 END)           AS Only_In_Secondary,
       SUM(comparable)                                                  AS Comparable_Rows,
       MIN(CASE WHEN in_p = 1 THEN ts_utc END)                          AS Primary_First_Hour_UTC,
       MAX(CASE WHEN in_p = 1 THEN ts_utc END)                          AS Primary_Last_Hour_UTC,
       MIN(CASE WHEN in_s = 1 THEN ts_utc END)                          AS Secondary_First_Hour_UTC,
       MAX(CASE WHEN in_s = 1 THEN ts_utc END)                          AS Secondary_Last_Hour_UTC,
       ROUND(corr(demand_p, demand_s), 6)                               AS Correlation,
       ROUND(AVG(demand_p - demand_s), 4)                               AS Bias_MW,
       ROUND(AVG(ABS(demand_p - demand_s)), 4)                          AS MAE_MW,
       ROUND(MAX(ABS(demand_p - demand_s)), 2)                          AS Max_Abs_Diff_MW,
       ROUND(100.0 * AVG(CASE WHEN comparable = 1 THEN CASE WHEN ABS(demand_p - demand_s) < 0.5 THEN 1.0 ELSE 0.0 END END), 2) AS Percent_Within_0_5_MW
FROM j JOIN ba_meta m ON m.ba = j.ba
GROUP BY m.ba_name, j.ba
ORDER BY BA_Code
