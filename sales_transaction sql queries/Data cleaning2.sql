-DATA EXPLORATION/DATA CLEANING

--Creating a new table
SELECT*
INTO Sales2
FROM Sales

SELECT COUNT (*) AS ROW_COUNT-- Total number of rows
FROM Sales2

--GRAIN TEST: is Order_ID really one order? (if it were, each Order_ID would have ONE customer and ONE date)
--Checking out for grain Order_ID or Transaction_ID
SELECT COUNT(*) AS OrderIdsWithMultipleRows,
       SUM(CASE WHEN Customers > 1 THEN 1 ELSE 0 END) AS WithDifferentCustomers,
       SUM(CASE WHEN Dates > 1 THEN 1 ELSE 0 END)     AS WithDifferentDates
FROM (SELECT Order_ID, COUNT(DISTINCT Customer_ID) AS Customers, COUNT(DISTINCT Order_Date) AS Dates
      FROM (SELECT DISTINCT * FROM dbo.sales2) d GROUP BY Order_ID HAVING COUNT(*) > 1) o;

--Checking for and removing Duplicates 
WITH Duplicates AS (
SELECT*,
ROW_NUMBER() OVER(PARTITION BY Transaction_id, Order_id, Customer_id ORDER BY Transaction_id) AS Rn
FROM Sales2
)
SELECT* 
FROM Duplicates
WHERE Rn >1

--Checking for nulls and blank spaces with sql automatic generator

DECLARE @sql NVARCHAR(MAX);
SELECT @sql = STRING_AGG(CAST(
    'SELECT ''' + c.name + ''' AS ColumnName, COUNT(*) - COUNT(NULLIF(LTRIM(RTRIM(' + QUOTENAME(c.name) + ')), '''')) AS Missing FROM dbo.sales2'
    AS NVARCHAR(MAX)), ' UNION ALL ')
FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.sales2');
EXEC sp_executesql @sql;

--standardization and Removal of hidden label variant
--     'male' with 'Male' and HIDES the problem. A binary collation shows every spelling.
SELECT 'Customer_Gender' AS Col, Customer_Gender COLLATE Latin1_General_BIN2 AS Val, COUNT(*) AS N FROM dbo.sales2 GROUP BY Customer_Gender COLLATE Latin1_General_BIN2
UNION ALL SELECT 'Region',          Region    COLLATE Latin1_General_BIN2,     COUNT(*) FROM dbo.sales2 GROUP BY Region          COLLATE Latin1_General_BIN2
UNION ALL SELECT 'City',            City    COLLATE Latin1_General_BIN2,    COUNT(*) FROM dbo.sales2 GROUP BY City            COLLATE Latin1_General_BIN2
UNION ALL SELECT 'Product_Category',Product_Category COLLATE Latin1_General_BIN2, COUNT(*) FROM dbo.sales2 GROUP BY Product_Category COLLATE Latin1_General_BIN2
UNION ALL SELECT 'Payment_Method',  Payment_Method COLLATE Latin1_General_BIN2, COUNT(*) FROM dbo.sales2 GROUP BY Payment_Method  COLLATE Latin1_General_BIN2
UNION ALL SELECT 'Order_Status',    Order_Status COLLATE Latin1_General_BIN2,   COUNT(*) FROM dbo.sales2 GROUP BY Order_Status    COLLATE Latin1_General_BIN2
ORDER BY Col, N DESC;

-- checking for  Out-of-range and impossible values
SELECT SUM(CASE WHEN TRY_CAST(Customer_Age AS DECIMAL(5,1)) < 16 OR TRY_CAST(Customer_Age AS DECIMAL(5,1)) > 90 THEN 1 ELSE 0 END) AS OddAges,
       SUM(CASE WHEN TRY_CAST(Quantity AS DECIMAL(9,2)) <= 0 THEN 1 ELSE 0 END)                    AS BadQuantity,
       SUM(CASE WHEN TRY_CAST(Discount_Percentage AS DECIMAL(9,2)) > 30 THEN 1 ELSE 0 END)         AS DiscountOver30,
       SUM(CASE WHEN TRY_CAST(Cost_Amount AS DECIMAL(18,2)) > TRY_CAST(Sales_Amount AS DECIMAL(18,2)) THEN 1 ELSE 0 END) AS CostAboveSales
FROM dbo.sales2;

GO
CREATE OR ALTER VIEW dbo.sales_clean_v AS
WITH typed AS (            -- STEP A: trim, blank -> NULL, convert text to real types, standardise labels
    
    SELECT
        NULLIF(LTRIM(RTRIM(Transaction_ID)),'')                                   AS TransactionID,
        NULLIF(LTRIM(RTRIM(Order_ID)),'')                                         AS OrderID,
        NULLIF(LTRIM(RTRIM(Customer_ID)),'')                                      AS CustomerID,
        NULLIF(LTRIM(RTRIM(Customer_Name)),'')                                    AS CustomerName,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Customer_Age)),'') AS INT)                    AS CustomerAge,
        CASE LOWER(NULLIF(LTRIM(RTRIM(Customer_Gender)),''))
             WHEN 'male' THEN 'Male' WHEN 'female' THEN 'Female'
             WHEN 'non-binary' THEN 'Non-binary' WHEN 'non binary' THEN 'Non-binary' END AS CustomerGender,
        NULLIF(LTRIM(RTRIM(Customer_Segment)),'')                                 AS CustomerSegment,
        NULLIF(LTRIM(RTRIM(Order_Date)),'')                                 AS OrderDate,
        NULLIF(LTRIM(RTRIM(Order_Time)),'')                                AS OrderTime,
        NULLIF(LTRIM(RTRIM(Sales_Channel)),'')                                    AS SalesChannel,
        NULLIF(LTRIM(RTRIM(Store_ID)),'')                                         AS StoreID,
        NULLIF(LTRIM(RTRIM(Store_Name)),'')                                       AS StoreName,
        NULLIF(LTRIM(RTRIM(Country)),'')                                          AS Country,
        CASE LOWER(NULLIF(LTRIM(RTRIM(Region)),''))
             WHEN 'north east' THEN 'Northeast' WHEN 'nrw' THEN 'North Rhine-Westphalia'
             WHEN 'british columbia' THEN 'British Columbia'
             ELSE NULLIF(LTRIM(RTRIM(Region)),'') END                             AS Region,
        CASE LOWER(NULLIF(LTRIM(RTRIM(City)),''))
             WHEN 'los angeles' THEN 'Los Angeles' WHEN 'munich' THEN 'Munich' WHEN 'new york' THEN 'New York'
             ELSE NULLIF(LTRIM(RTRIM(City)),'') END                               AS City,
        NULLIF(LTRIM(RTRIM(Product_ID)),'')                                       AS ProductID,
        NULLIF(LTRIM(RTRIM(Product_Name)),'')                                     AS ProductName,
        CASE LOWER(NULLIF(LTRIM(RTRIM(Product_Category)),''))
             WHEN 'electronics' THEN 'Electronics' WHEN 'furniture' THEN 'Furniture' 
             WHEN 'office supplies' THEN 'Office Supplies' WHEN 'appliances' THEN 'Appliances'
             ELSE NULLIF(LTRIM(RTRIM(Product_Category)),'') END                   AS ProductCategory,
        NULLIF(LTRIM(RTRIM(Product_Subcategory)),'')                              AS ProductSubcategory,
        NULLIF(LTRIM(RTRIM(Quantity)),'') AS  Quantity,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Unit_Price)),'') AS DECIMAL(18,4))                                       AS UnitPrice,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Discount_Percentage)),'') AS DECIMAL(18,4))                              AS DiscountPct,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Sales_Amount)),'') AS DECIMAL(18,4))                                     AS SalesAmount,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Cost_Amount)),'') AS DECIMAL(18,4))                                      AS CostAmount,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Profit)),'') AS DECIMAL(18,4))                                           AS ProfitReported,
        CASE REPLACE(LOWER(NULLIF(LTRIM(RTRIM(Payment_Method)),'')),' ','')
             WHEN 'creditcard' THEN 'Credit Card' WHEN 'debitcard' THEN 'Debit Card' WHEN 'paypal' THEN 'PayPal'
             WHEN 'banktransfer' THEN 'Bank Transfer' WHEN 'applepay' THEN 'Apple Pay' WHEN 'cash' THEN 'Cash'
             ELSE NULLIF(LTRIM(RTRIM(Payment_Method)),'') END                     AS PaymentMethod,
        CASE LOWER(NULLIF(LTRIM(RTRIM(Order_Status)),''))
             WHEN 'completed' THEN 'Completed' WHEN 'shipped' THEN 'Shipped' WHEN 'returned' THEN 'Returned'
             WHEN 'processing' THEN 'Processing' WHEN 'cancelled' THEN 'Cancelled'
             ELSE NULLIF(LTRIM(RTRIM(Order_Status)),'') END                       AS OrderStatus,
        NULLIF(LTRIM(RTRIM(Shipping_Method)),'')                                  AS ShippingMethod,
        TRY_CAST(NULLIF(LTRIM(RTRIM(Delivery_Days)),'') AS INT)                                   AS DeliveryDays,
        NULLIF(LTRIM(RTRIM(Return_Flag)),'')                                      AS ReturnFlag,
        NULLIF(LTRIM(RTRIM(Return_Reason)),'')                                    AS ReturnReason,
        NULLIF(LTRIM(RTRIM(Sales_Representative)),'')                             AS SalesRepresentative,
        NULLIF(LTRIM(RTRIM(Promotion_Code)),'')                                   AS PromotionCode,
        NULLIF(LTRIM(RTRIM(Customer_Rating)),'')                                  AS CustomerRating,
        NULLIF(LTRIM(RTRIM(Inventory_Level)),'')                                AS InventoryLevel
        FROM dbo.sales2
        ),
dedup AS (                 -- STEP B: exact duplicates (same Transaction_ID) -> keep one
    SELECT t.*, ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY TransactionID) AS rn
    FROM typed t
),
base AS (
    SELECT * FROM dedup WHERE rn = 1
),
Filled AS (                -- STEP C: invalid ages -> NULL, then recover missing attributes from other rows of the same ID
    SELECT b.*,
        CASE WHEN CustomerAge < 16 OR CustomerAge > 90 THEN NULL ELSE CustomerAge END AS AgeValid
    FROM base b
),
Recovered AS (              -- STEP D: Filling in null columns
    SELECT f.*,
        COALESCE(CustomerName,   MAX(CustomerName)   OVER (PARTITION BY CustomerID),'Unknown') AS CustomerNameClean,
        COALESCE(CustomerGender, MAX(CustomerGender) OVER (PARTITION BY CustomerID),'Unknown') AS CustomerGenderClean,   
        COALESCE(AgeValid,       MAX(AgeValid)       OVER (PARTITION BY CustomerID)) AS CustomerAgeClean,
        COALESCE(ProductName,    MAX(ProductName)    OVER (PARTITION BY ProductID))  AS ProductNameClean
        --AVG(UnitPrice) OVER (PARTITION BY ProductID)                                 AS ProductAvgPrice,
       -- COUNT(*)       OVER (PARTITION BY OrderID)                                   AS RowsWithSameOrderID
    FROM filled f
    )

  SELECT                      -- STEP E: final columns
    TransactionID, OrderID, CustomerID, CustomerNameClean AS CustomerName, CustomerAgeClean AS CustomerAge,
    CustomerGenderClean AS CustomerGender, CustomerSegment, OrderDate, OrderTime,
    YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth,
    SalesChannel, StoreID, StoreName, Country, Region, City, ProductID, ProductNameClean AS ProductName,
    ProductCategory, ProductSubcategory,  CASE WHEN  Quantity <= 0 THEN NULL  ELSE Quantity END AS Quantity,
    UnitPrice,
   CASE WHEN DiscountPct > 30 OR DiscountPct < 0 THEN NULL ELSE DiscountPct END AS DiscountPct, SalesAmount, CostAmount,  
    ProfitReported,
    COALESCE(PaymentMethod, 'Unknown')                                AS PaymentMethod,
    OrderStatus, ShippingMethod,DeliveryDays, ReturnFlag,
    CASE WHEN ReturnReason IS NULL THEN 'Not Returned' ELSE ReturnReason END AS ReturnReason,
    SalesRepresentative,
    COALESCE(PromotionCode, 'No Promo')                               AS PromotionCode,
    CAST(CustomerRating AS INT) AS CustomerRating, CAST(InventoryLevel AS INT) AS InventoryLevel
   FROM Recovered
   GO
   
  --End of Data Cleaning