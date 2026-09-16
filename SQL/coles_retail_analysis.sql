# Australian Retail Sales Analytics
# Author: Evita
# Tool: MySQL
#-----------------------------------
# Phase 1: Data Cleaning
#-----------------------------------
CREATE DATABASE coles_retail_db;
USE coles_retail_db;

SELECT * FROM sales LIMIT 5;
SELECT * FROM stores LIMIT 5;

DESCRIBE sales;
DESCRIBE stores;

ALTER TABLE sales
DROP COLUMN MyUnknownColumn;

ALTER TABLE stores
DROP COLUMN MyUnknownColumn;

ALTER TABLE sales
RENAME COLUMN Coles_StoreIDNo TO store_id,
RENAME COLUMN Expec_Revenue TO expected_revenue,
RENAME COLUMN Gross_Sale TO gross_sale,
RENAME COLUMN Sales_Cost TO sales_cost,
RENAME COLUMN Targeted_Quarter TO quarter,
RENAME COLUMN Coles_Forecast TO forecast;

ALTER TABLE stores
RENAME COLUMN Coles_StoreID TO store_id,
RENAME COLUMN Store_Location TO state,
RENAME COLUMN Customer_Count TO customer_count,
RENAME COLUMN Staff_Count TO staff_count,
RENAME COLUMN Store_Area TO store_area;

DESCRIBE sales;
DESCRIBE stores;

SELECT
    SUM(store_id IS NULL) AS missing_store,
    SUM(expected_revenue IS NULL) AS missing_expected_revenue,
    SUM(gross_sale IS NULL) AS missing_gross_sale,
    SUM(sales_cost IS NULL) AS missing_sales_cost,
    SUM(quarter IS NULL) AS missing_quarter,
    SUM(forecast IS NULL) AS missing_forecast
FROM sales;

SELECT
    SUM(store_id IS NULL) AS missing_store,
    SUM(state IS NULL) AS missing_state,
    SUM(customer_count IS NULL) AS missing_customers,
    SUM(staff_count IS NULL) AS missing_staff,
    SUM(store_area IS NULL) AS missing_area
FROM stores;

SELECT
    store_id,
    COUNT(*) AS duplicate_count
FROM stores
GROUP BY store_id
HAVING COUNT(*) > 1;

SELECT
    COUNT(*) AS matching_stores
FROM sales s
JOIN stores st
ON s.store_id = st.store_id;

#-----------------------------------
#Phase 2: Joining the Data
#-----------------------------------

CREATE VIEW retail_analytics AS
SELECT
    s.store_id,
    st.state,
    s.expected_revenue,
    s.gross_sale,
    s.sales_cost,
    (s.gross_sale - s.sales_cost) AS profit,
    ROUND(((s.gross_sale - s.sales_cost)/s.gross_sale)*100,2) AS profit_margin,
    s.quarter,
    s.forecast,
    st.customer_count,
    st.staff_count,
    st.store_area,
    ROUND(s.gross_sale/st.customer_count,4) AS sales_per_customer,
    ROUND(s.gross_sale/st.staff_count,2) AS sales_per_staff
FROM sales s
JOIN stores st
ON s.store_id = st.store_id;

#-----------------------------------
# Phase 3: Descriptive Statistics
#-----------------------------------

# Overall Business Summary
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT store_id) AS total_stores,
    ROUND(SUM(gross_sale),0) AS total_revenue,
    ROUND(SUM(profit),0) AS total_profit,
    ROUND(AVG(profit_margin),2) AS avg_profit_margin
FROM retail_analytics;

# Revenue by State
SELECT
    state,
    ROUND(SUM(gross_sale),0) AS revenue,
    ROUND(SUM(profit),0) AS profit
FROM retail_analytics
GROUP BY state
ORDER BY revenue DESC;

# Quarter Performance
SELECT
    quarter,
    COUNT(*) AS transactions,
    ROUND(SUM(gross_sale),0) AS revenue,
    ROUND(AVG(profit_margin),2) AS avg_margin
FROM retail_analytics
GROUP BY quarter;

# Forecast
SELECT
    forecast,
    COUNT(*) AS stores,
    ROUND(AVG(gross_sale),2) AS avg_sales
FROM retail_analytics
GROUP BY forecast;

# Descriptive Statistics
SELECT
    MIN(gross_sale) AS min_sales,
    MAX(gross_sale) AS max_sales,
    ROUND(AVG(gross_sale),2) AS avg_sales,
    MIN(profit) AS min_profit,
    MAX(profit) AS max_profit,
    ROUND(AVG(profit),2) AS avg_profit
FROM retail_analytics;

#-----------------------------------
# Phase 4: Business Analysis
#-----------------------------------

# Top 10 most profitable stores
SELECT
    RANK() OVER(ORDER BY profit DESC) AS profit_rank,
    store_id,
    state,
    gross_sale,
    profit,
    profit_margin
FROM retail_analytics
LIMIT 10;

# Rank states by revenue
SELECT
    RANK() OVER(ORDER BY SUM(gross_sale) DESC) AS state_rank,
    state,
    SUM(gross_sale) AS revenue,
    SUM(profit) AS profit
FROM retail_analytics
GROUP BY state;

#Customer traffic segmentation (CTE)
WITH customer_segment AS (
    SELECT *,
           CASE
               WHEN customer_count >= 40000 THEN 'High Traffic'
               WHEN customer_count >= 15000 THEN 'Medium Traffic'
               ELSE 'Low Traffic'
           END AS traffic_level
    FROM retail_analytics
)

SELECT
    traffic_level,
    COUNT(*) AS stores,
    ROUND(AVG(gross_sale),2) AS avg_sales,
    ROUND(AVG(profit),2) AS avg_profit
FROM customer_segment
GROUP BY traffic_level;

# Staff productivity
SELECT
    store_id,
    state,
    staff_count,
    sales_per_staff,
    RANK() OVER(ORDER BY sales_per_staff DESC) AS productivity_rank
FROM retail_analytics
LIMIT 10;

# Expected vs Actual
SELECT
    store_id,
    expected_revenue,
    gross_sale,
    (gross_sale - expected_revenue) AS revenue_variance,
    CASE
        WHEN gross_sale >= expected_revenue THEN 'Exceeded'
        ELSE 'Below Expectation'
    END AS performance
FROM retail_analytics;

#-----------------------------------
/* END OF SQL ANALYSIS
 Phase 5 (Power BI) is completed in:
   /powerbi/Australian_Retail_Dashboard.pbix */