-- SQL 2: quy mô nhu cầu và tính mùa vụ theo từng BA (UTC end-of-hour, chỉ giờ hợp lệ)
WITH overall AS (                      -- (a) thống kê quy mô và tỷ số cuối tuần / ngày thường
    SELECT ba,
           COUNT(demand)       AS n_hours,
           AVG(demand)         AS mean_mw,
           MAX(demand)         AS peak_mw,
           MIN(demand)         AS min_mw,
           STDDEV_SAMP(demand) AS std_mw,
           AVG(demand) FILTER (WHERE dow_local >= 5) / AVG(demand) FILTER (WHERE dow_local < 5) AS weekend_ratio
    FROM clean GROUP BY ba),
monthly AS (                           -- (b) trung bình theo (năm, tháng UTC) kèm độ phủ của tháng
    SELECT ba, YEAR(ts_utc) AS yr, MONTH(ts_utc) AS mon,
           AVG(demand)   AS month_mean_mw,
           COUNT(demand) AS n_valid,
           DAY(LAST_DAY(CAST(MIN(ts_utc) AS DATE))) * 24 AS n_expected
    FROM clean GROUP BY ba, YEAR(ts_utc), MONTH(ts_utc)),
season AS (                            -- (c) hình dạng mùa: trung bình theo tháng trong năm, chỉ tháng đủ dữ liệu
    SELECT ba, mon, AVG(month_mean_mw) AS season_mean_mw
    FROM monthly WHERE n_valid >= 0.9 * n_expected
    GROUP BY ba, mon),
season_sum AS (
    SELECT ba, arg_max(mon, season_mean_mw) AS peak_month, arg_min(mon, season_mean_mw) AS low_month,
           MAX(season_mean_mw) AS season_max, MIN(season_mean_mw) AS season_min
    FROM season GROUP BY ba),
hourly AS (                            -- (d) đường cong ngày: trung bình theo giờ địa phương (hour-ending)
    SELECT ba, hour_local, AVG(demand) AS hour_mean_mw FROM clean GROUP BY ba, hour_local),
hour_sum AS (
    SELECT ba, arg_max(hour_local, hour_mean_mw) AS peak_hour,
           MAX(hour_mean_mw) / MIN(hour_mean_mw) AS daily_max_min_ratio
    FROM hourly GROUP BY ba)
SELECT m.ba_name                                              AS BA_Name,
       o.ba                                                   AS BA_Code,
       o.n_hours                                              AS Number_of_Valid_Hours,
       ROUND(o.mean_mw, 1)                                    AS Average_Demand_MW,
       ROUND(o.peak_mw, 1)                                    AS Peak_Demand_MW,
       ROUND(o.min_mw, 1)                                     AS Minimum_Demand_MW,
       ROUND(o.std_mw, 1)                                     AS Demand_Std_MW,
       ROUND(100.0 * o.std_mw / o.mean_mw, 1)                 AS CV_Percent,
       s.peak_month                                           AS Peak_Month,
       s.low_month                                            AS Low_Month,
       ROUND(100.0 * (s.season_max - s.season_min) / o.mean_mw, 1) AS Seasonal_Range_Percent,
       h.peak_hour                                            AS Peak_Local_Hour_Ending,
       ROUND(h.daily_max_min_ratio, 2)                        AS Daily_Max_Min_Ratio,
       ROUND(o.weekend_ratio, 3)                              AS Weekend_to_Weekday_Ratio
FROM overall o
JOIN season_sum s ON s.ba = o.ba
JOIN hour_sum   h ON h.ba = o.ba
JOIN ba_meta    m ON m.ba = o.ba
ORDER BY Average_Demand_MW DESC
