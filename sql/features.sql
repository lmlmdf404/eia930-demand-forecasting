
CREATE OR REPLACE TABLE feat AS
SELECT ba, ts_utc, demand, eia_fc,
       co2_intensity_generated, co2_intensity_consumed,
       HOUR(ts_utc) AS hr, ISODOW(ts_utc) - 1 AS dow, MONTH(ts_utc) AS mon, DAYOFYEAR(ts_utc) AS doy,   -- lịch của giờ phát hành (UTC), dow: Thứ Hai = 0
       tgt_hr_local, tgt_dow_local, tgt_is_weekend_local, tgt_mon_local,                                 -- lịch của giờ ĐÍCH (giờ địa phương), biết trước
       LAG(demand, 1) OVER w AS y_lag1,
       LAG(demand, 2) OVER w AS y_lag2,
       LAG(demand, 3) OVER w AS y_lag3,
       LAG(demand, 24) OVER w AS y_lag24,
       LAG(demand, 48) OVER w AS y_lag48,
       LAG(demand, 144) OVER w AS y_lag144,
       LAG(demand, 168) OVER w AS y_lag168,
       CASE WHEN COUNT(demand) OVER w24 = 24 THEN AVG(demand)         OVER w24 END AS y_ma_season,   -- cần đủ 24 giờ
       CASE WHEN COUNT(demand) OVER w24 = 24 THEN STDDEV_SAMP(demand) OVER w24 END AS y_sd_season,
       demand - LAG(demand, 1) OVER w AS y_diff1,
       LAG(co2_intensity_generated, 24) OVER w AS co2_intensity_generated_lag_season,
       LAG(co2_intensity_consumed, 24) OVER w AS co2_intensity_consumed_lag_season,
       LEAD(demand, 24) OVER w AS y_h24,          -- target: đây là nơi DUY NHẤT dùng giá trị tương lai cho mô hình
       LEAD(eia_fc, 24) OVER w AS eia_fc_target              -- dự báo EIA cho giờ ĐÍCH (chỉ để so sánh, không phải đặc trưng)
FROM grid
WINDOW w   AS (PARTITION BY ba ORDER BY ts_utc),
       w24 AS (PARTITION BY ba ORDER BY ts_utc ROWS BETWEEN 23 PRECEDING AND CURRENT ROW)
