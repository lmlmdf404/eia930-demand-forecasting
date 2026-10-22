-- SQL 3a: demand và CO2 intensity TRONG TỪNG BA (không gộp BA, để quy mô và cơ cấu nguồn điện giữa các BA không làm nhiễu)
WITH base AS (
    SELECT ba, hour_local, demand,
           co2_intensity_generated AS co2_gen,
           co2_intensity_consumed  AS co2_con
    FROM clean
    WHERE co2_intensity_generated IS NOT NULL AND co2_intensity_consumed IS NOT NULL),
dev AS (                               -- độ lệch so với đường cong ngày trung bình của chính BA đó
    SELECT ba, demand, co2_gen, co2_con,
           demand  - AVG(demand)  OVER (PARTITION BY ba, hour_local) AS demand_dev,
           co2_gen - AVG(co2_gen) OVER (PARTITION BY ba, hour_local) AS co2_gen_dev
    FROM base)
SELECT m.ba_name                                     AS BA_Name,
       d.ba                                          AS BA_Code,
       COUNT(*)                                      AS Number_of_Matched_Hours,
       ROUND(MIN(d.co2_gen), 3)                      AS CO2_Generated_Min,
       ROUND(MAX(d.co2_gen), 3)                      AS CO2_Generated_Max,
       ROUND(100.0 * AVG(CASE WHEN d.co2_gen = 0 THEN 1.0 ELSE 0.0 END), 1) AS Percent_Zero_CO2_Generated,
       ROUND(corr(d.demand, d.co2_gen), 3)           AS Corr_Demand_CO2_Generated,
       ROUND(corr(d.demand, d.co2_con), 3)           AS Corr_Demand_CO2_Consumed,
       ROUND(corr(d.demand_dev, d.co2_gen_dev), 3)   AS Corr_After_Removing_Hour_Profile
FROM dev d JOIN ba_meta m ON m.ba = d.ba
GROUP BY m.ba_name, d.ba
ORDER BY BA_Code
