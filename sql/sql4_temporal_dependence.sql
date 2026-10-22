-- SQL 4: demand tại giờ t so với đúng 24 giờ và đúng 168 giờ trước đó (self-join theo BA và timestamp, UTC end-of-hour)
SELECT m.ba_name                                                           AS BA_Name,
       cur.ba                                                              AS BA_Code,
       COUNT(*)                                                            AS Number_of_Valid_Hours,
       COUNT(p24.demand)                                                   AS Matched_Hours_Lag24,
       ROUND(corr(cur.demand, p24.demand), 3)                              AS Corr_Lag24,
       ROUND(AVG(ABS(cur.demand - p24.demand)), 1)                         AS MAE_Lag24_MW,
       ROUND(100.0 * AVG(ABS(cur.demand - p24.demand) / p24.demand), 2)    AS Mean_Abs_Change_Percent_Lag24,
       COUNT(p168.demand)                                                  AS Matched_Hours_Lag168,
       ROUND(corr(cur.demand, p168.demand), 3)                             AS Corr_Lag168,
       ROUND(AVG(ABS(cur.demand - p168.demand)), 1)                        AS MAE_Lag168_MW,
       ROUND(100.0 * AVG(ABS(cur.demand - p168.demand) / p168.demand), 2)  AS Mean_Abs_Change_Percent_Lag168
FROM clean cur
LEFT JOIN clean p24  ON p24.ba  = cur.ba AND p24.ts_utc  = cur.ts_utc - INTERVAL 24 HOUR
LEFT JOIN clean p168 ON p168.ba = cur.ba AND p168.ts_utc = cur.ts_utc - INTERVAL 168 HOUR
JOIN ba_meta m ON m.ba = cur.ba
GROUP BY m.ba_name, cur.ba
ORDER BY BA_Code
