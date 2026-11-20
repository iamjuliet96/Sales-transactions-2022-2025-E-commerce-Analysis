--Data Analysis
--5 Questions  
/*1. Which countries, regions and sales channels generate the most revenue and profit, and where is the profit margin weakest relative to sales?
2. At what discount level do transactions become unprofitable, and how much profit do discounts above that level give away?
3. Which product categories and subcategories have the highest return rates, and which return reasons cost the most revenue?
4. How have revenue, profit, order volume and average order value trended by month and year from 2022 to 2025, and is there seasonality?
5. Do delivery time and shipping method affect customer ratings and returns? My quick check showed ratings staying flat across delivery times,
so a “no relationship” result would be a valid finding.*/
  
--Question 1 
-- Which countries, regions and sales channels generate the most revenue and profit, and where is the profit margin weakest relative to sales?

SELECT *
from sales_clean_v

--A. For countries
SELECT
Country,
COUNT(*) AS Transactions,
SUM(salesamount) AS Net_Revenue,
SUM(Profitreported)AS Net_Profit,
(100.0*SUM(Profitreported)/SUM(salesamount))AS Margin_Pct,
ROUND(SUM(Salesamount)/COUNT(*),2) AS AvgTransactionValue,
ROUND(100.0* SUM(Salesamount)/SUM(SUM(salesamount)) OVER (),2) AS Share_pct
FROM Sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled', 'Returned')
GROUP BY Country
ORDER BY Net_Profit DESC

--B. For Regions
SELECT
Region,
--Country,
COUNT(*) AS Transactions,
SUM(salesamount) AS Net_Revenue,
SUM(Profitreported)AS Net_Profit,
(100.0*SUM(Profitreported)/SUM(salesamount))AS Margin_Pct,
ROUND(SUM(Salesamount)/COUNT(*),2) AS AvgTransactionValue,
ROUND(100.0* SUM(Salesamount)/SUM(SUM(salesamount)) OVER (),2) AS Share_pct
FROM Sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled', 'Returned')
GROUP BY Region
ORDER BY Net_Revenue DESC

--c. For saleschannel
SELECT
Saleschannel,
COUNT(*) AS Transactions,
SUM(salesamount) AS Net_Revenue,
SUM(Profitreported)AS Net_Profit,
(100.0*SUM(Profitreported)/SUM(salesamount))AS Margin_Pct,
SUM(Salesamount)/COUNT(*) AS AvgTransactionValue,
ROUND(100.0* SUM(Salesamount)/SUM(SUM(salesamount)) OVER (),2) AS Share_pct
FROM Sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled', 'Returned')
GROUP BY Saleschannel
ORDER BY Net_Revenue DESC

--Where is the profit margin weakest relative to sales?
WITH Seg AS (
SELECT
    Country,
    Region,
    Saleschannel,
    COUNT(*) AS Transactions,
    SUM(Salesamount) AS NetRevenue,
    SUM(Profitreported) AS NetProfit,
    (100.0*SUM(Profitreported)/SUM(salesamount))AS Margin_Pct
FROM Sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled', 'Returned')
GROUP BY Country,Region,Saleschannel
),
Base AS(
SELECT
100*SUM(Profitreported)/SUM(Salesamount) AS Overallmarginpct
FROM sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled', 'Returned')
)
SELECT S.*,
B.Overallmarginpct,
CASE WHEN S.Margin_pct > B.Overallmarginpct THEN 'Above Margin' ELSE 'Below Margin' END AS Margin_status
FROM Seg S
CROSS JOIN Base B
ORDER BY Margin_pct

--Question 2. 
--At what discount level do transactions become unprofitable, and how much profit do discounts above that level give away?
SELECT 
Discountpct, 
COUNT(*) AS Transactions,
SUM(Salesamount) AS Netrevenue,
SUM(Profitreported) AS Netprofit,
100.0*SUM(Profitreported)/SUM(SalesAmount) AS MarginPct,
100.0 * SUM(CASE WHEN Profitreported < 0 THEN 1 ELSE 0 END) / COUNT(*) AS LossMakingPct
FROM Sales_clean_v
WHERE Orderstatus NOT IN ('Cancelled','Returned')
GROUP BY Discountpct
ORDER BY Netrevenue DESC
--How much profit do discounts above that level give away?
SELECT
    SUM(Profitreported) AS Profitgiveaway,
    COUNT(*) AS Transactions,
    100.0*SUM(Profitreported)/SUM(SalesAmount) AS MarginPct
FROM Sales_clean_v
WHERE Discountpct =30
AND Orderstatus NOT IN ('Cancelled','Returned')

--Question 3
--Which product categories and subcategories have the highest return rates, and which return reasons cost the most revenue?--
SELECT
    COUNT(*) AS Total_items,
    SUM(CASE WHEN Returnflag = 1 THEN 1 ELSE 0 END) AS Return_totals,
    CAST(100.0*SUM(CASE WHEN ReturnFlag = 1 THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2))  AS ReturnRatePct,
    SUM(CASE WHEN Returnflag = 1 THEN SalesAMOUNT ELSE 0 END) AS Revenue_lost,
    ProductCategory,
    Productsubcategory
FROM Sales_clean_v
WHERE OrderStatus <> 'Cancelled'
GROUP BY ProductCategory,
Productsubcategory
ORDER BY revenue_lost DESC

--which return reasons cost the most revenue?
SELECT
    ReturnReason,
    COUNT(*) AS Total_items, 
    SUM(Salesamount) AS Revenue_lost,
    CAST(100.0*SUM(SalesAmount)/SUM(SUM(SalesAmount)) OVER () AS DECIMAL(5,2)) AS SharePct
FROM Sales_clean_v
WHERE OrderStatus <> 'Cancelled' AND Returnflag ='1'
GROUP BY ReturnReason
ORDER BY SUM(Salesamount) DESC

--Question 4
--How have revenue, profit, order volume and average order value trended by month and year from 2022 to 2025, and is there seasonality?

SELECT
 OrderYear,
  OrderMonth,
     COUNT(*) AS Transaction_volume,
     SUM(Salesamount) AS Net_Revenue,
     SUM(Profitreported) AS Net_Profit,
     CAST(100.0*SUM(Profitreported)/SUM(Salesamount) AS DECIMAL(5,2)) AS MarginPct,
     CAST(SUM(Salesamount)/COUNT(*)AS DECIMAL(10,2)) AS AvgTransactionValue,
     CAST(100.0*(SUM(Salesamount) - LAG(SUM(Salesamount)) OVER (ORDER BY OrderYear,OrderMonth))/LAG(SUM(Salesamount)) OVER (ORDER BY OrderYear,OrderMonth) AS DECIMAL(6,2)) AS MoMRevenuePct
 FROM Sales_clean_v
 WHERE Orderstatus NOT IN ('Cancelled','Returned')
 GROUP BY OrderYear, OrderMonth
 ORDER BY OrderYear,OrderMonth

 --For YOY Revenue
 SELECT
 OrderYear,
     COUNT(*) AS Transaction_volume,
     SUM(Salesamount) AS Net_Revenue,
     SUM(Profitreported) AS Net_Profit,
     CAST(100.0*SUM(Profitreported)/SUM(Salesamount) AS DECIMAL(5,2)) AS MarginPct,
     CAST(SUM(Salesamount)/COUNT(*)AS DECIMAL(10,2)) AS AvgTransactionValue,
     CAST(100.0*(SUM(Salesamount) - LAG(SUM(Salesamount)) OVER (ORDER BY OrderYear))/LAG(SUM(Salesamount)) OVER (ORDER BY OrderYear) AS DECIMAL(6,2)) AS YoYRevenuePct
 FROM Sales_clean_v
 WHERE Orderstatus NOT IN ('Cancelled','Returned')
 GROUP BY OrderYear
 ORDER BY OrderYear

--and is there seasonality?
WITH M AS (
    SELECT OrderMonth, SUM(SalesAmount) AS Rev, COUNT(*) AS Transactions
    FROM dbo.sales_clean_V
    WHERE OrderStatus NOT IN ('Cancelled','Returned')
    GROUP BY OrderMonth
)
SELECT OrderMonth, Transactions,
       CAST(Rev AS DECIMAL(14,0)) AS NetRevenue,
       CAST(Rev/AVG(Rev) OVER () AS DECIMAL(5,2)) AS SeasonalityIndex
FROM m
ORDER BY OrderMonth;
 
--Question 5
--Do delivery time and shipping method affect customer ratings and returns? 
--Shipping method vs delivery time, rating and returns (for all)
SELECT  
shippingMethod,
COUNT(*) AS Lines,
CAST(AVG(Deliverydays) AS DECIMAL(5,2)) AS Avg_delivery_days,
CAST(AVG(CustomerRating)AS DECIMAL(4,2))AS Avg_customer_rate,
SUM(CASE WHEN ReturnFlag = '1' THEN 1 ELSE 0 END) AS Return_Total,
CAST(100.0*SUM(CASE WHEN ReturnFlag = '1' THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS ReturnRatePct
FROM sales_clean_v
WHERE OrderStatus NOT IN ('Cancelled') AND Deliverydays IS NOT NULL
GROUP BY shippingMethod
ORDER BY Avg_delivery_days DESC


--Delivery-time buckets vs rating and return rate (non-pickup)
SELECT CASE WHEN DeliveryDays <= 1 THEN '1. 0-1 days'
            WHEN DeliveryDays <= 3 THEN '2. 2-3 days'
            WHEN DeliveryDays <= 5 THEN '3. 4-5 days'
            ELSE                        '4. 6+ days' END AS DeliveryBucket,
       COUNT(*) AS Lines,
       CAST(AVG(1.0*CustomerRating) AS DECIMAL(4,2)) AS AvgRating,
       CAST(100.0*SUM(CASE WHEN ReturnFlag = '1' THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS ReturnRatePct
FROM dbo.sales_clean_v
WHERE OrderStatus <> 'Cancelled'
  AND ShippingMethod <> 'Pickup'
  AND DeliveryDays IS NOT NULL
GROUP BY CASE WHEN DeliveryDays <= 1 THEN '1. 0-1 days'
              WHEN DeliveryDays <= 3 THEN '2. 2-3 days'
              WHEN DeliveryDays <= 5 THEN '3. 4-5 days'
              ELSE                        '4. 6+ days' END
ORDER BY DeliveryBucket;



