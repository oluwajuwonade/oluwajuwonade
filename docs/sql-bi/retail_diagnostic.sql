-- Retail Sales Diagnostic: SQL + BI analytical layer
-- Source: oluwajuwonade/AI-Powered-Retail-Sales-Diagnostic
-- Dialect: DuckDB-compatible analytical SQL
-- Purpose: expose validated retail metrics to a BI layer.
--
-- Expected source columns include:
-- Date, Month, Product, Category, Region, Customer Segment,
-- Units Sold, Revenue, Cost, Profit, Discount, Acquisition Channel.

-- 1. Clean KPI view
CREATE VIEW retail_kpi_monthly AS
SELECT
  CAST(Date AS DATE) AS sale_date,
  strftime(CAST(Date AS DATE), '%Y-%m') AS month,
  Product AS product,
  Category AS category,
  Region AS region,
  "Customer Segment" AS customer_segment,
  "Acquisition Channel" AS acquisition_channel,
  SUM("Units Sold") AS units,
  SUM(Revenue) AS revenue,
  SUM(Cost) AS cost,
  SUM(Profit) AS profit,
  SUM(Discount) AS discount_sum,
  COUNT(*) AS row_count,
  AVG(Discount) AS avg_discount,
  SUM(Revenue) / NULLIF(SUM("Units Sold"), 0) AS asp,
  SUM(Profit) / NULLIF(SUM(Revenue), 0) AS margin
FROM retail_sales_cleaned
GROUP BY 1,2,3,4,5,6,7;

-- 2. H1/H2 management KPI layer
WITH period AS (
  SELECT
    CASE WHEN EXTRACT(MONTH FROM sale_date) <= 6 THEN 'H1' ELSE 'H2' END AS half,
    revenue, units, profit, discount_sum, row_count
  FROM retail_kpi_monthly
)
SELECT
  half,
  SUM(revenue) AS revenue,
  SUM(units) AS units,
  SUM(revenue) / NULLIF(SUM(units),0) AS asp,
  SUM(profit) AS profit,
  SUM(profit) / NULLIF(SUM(revenue),0) AS margin,
  SUM(discount_sum) / NULLIF(SUM(row_count),0) AS avg_discount
FROM period
GROUP BY half
ORDER BY half;

-- 3. Product diagnostic
SELECT
  product,
  SUM(units) AS units,
  SUM(revenue) AS revenue,
  SUM(profit) AS profit,
  SUM(revenue) / NULLIF(SUM(units),0) AS asp,
  SUM(profit) / NULLIF(SUM(revenue),0) AS margin
FROM retail_kpi_monthly
GROUP BY product
ORDER BY revenue DESC;

-- 4. Channel quality check
SELECT
  acquisition_channel,
  SUM(revenue) AS revenue,
  SUM(units) AS units,
  SUM(profit) AS profit,
  SUM(profit) / NULLIF(SUM(revenue),0) AS margin,
  SUM(discount_sum) / NULLIF(SUM(row_count),0) AS avg_discount
FROM retail_kpi_monthly
GROUP BY acquisition_channel
ORDER BY margin DESC;

-- 5. KPI reconciliation
SELECT
  COUNT(*) AS rows_in_kpi_layer,
  SUM(revenue) AS revenue_total,
  SUM(units) AS units_total,
  SUM(profit) AS profit_total
FROM retail_kpi_monthly;

-- 6. Suggested Power BI measures
-- Revenue = SUM(retail_kpi_monthly[revenue])
-- Units = SUM(retail_kpi_monthly[units])
-- ASP = DIVIDE([Revenue], [Units])
-- Profit = SUM(retail_kpi_monthly[profit])
-- Margin = DIVIDE([Profit], [Revenue])
-- Avg Discount = DIVIDE(SUM(retail_kpi_monthly[discount_sum]), SUM(retail_kpi_monthly[row_count]))
