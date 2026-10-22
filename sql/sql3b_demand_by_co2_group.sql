-- SQL 3b: nhu cầu tương đối theo 5 nhóm phân vị CO2 generated, tính TRONG TỪNG BA
-- (nhóm xác định bằng phân vị của chính BA, các giá trị trùng nhau luôn nằm cùng một nhóm, nên nhóm có thể không đều hoặc rỗng khi nhiều giờ CO2 = 0)
WITH base AS (
    SELECT ba, co2_intensity_generated AS co2_gen,
           demand / AVG(demand) OVER (PARTITION BY ba) AS relative_demand
    FROM clean WHERE co2_intensity_generated IS NOT NULL),
thr AS (
    SELECT ba, quantile_cont(co2_gen, [0.2, 0.4, 0.6, 0.8]) AS q FROM base GROUP BY ba),
grp AS (
    SELECT b.ba, b.co2_gen, b.relative_demand,
           CASE WHEN b.co2_gen <= t.q[1] THEN 1
                WHEN b.co2_gen <= t.q[2] THEN 2
                WHEN b.co2_gen <= t.q[3] THEN 3
                WHEN b.co2_gen <= t.q[4] THEN 4
                ELSE 5 END AS CO2_Group
    FROM base b JOIN thr t ON t.ba = b.ba)
SELECT ba AS BA_Code, CO2_Group,
       ROUND(MIN(co2_gen), 3)          AS Min_CO2_Generated,
       ROUND(MAX(co2_gen), 3)          AS Max_CO2_Generated,
       ROUND(AVG(relative_demand), 3)  AS Average_Relative_Demand,
       COUNT(*)                        AS Number_of_Hours
FROM grp GROUP BY ba, CO2_Group
ORDER BY BA_Code, CO2_Group
