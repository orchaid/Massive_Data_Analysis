--======================================================
-- This is an EDA of Microsoft AdventureWorks dataset
--======================================================

--------------------------------------------------

-- checking tables for the analysis
SELECT 
	*
FROM  Production.Product -- info about product like name

SELECT
	*
FROM Sales.SalesOrderDetail -- Fact table

SELECT * FROM Sales.SalesOrderHeader -- Fact Table with info about IDs and dates

SELECT * FROM Sales.Customer -- Contains IDs like personID and StoreID

SELECT * FROM Person.Person -- contains info about Customers' names

SELECT * FROM HumanResources.Employee -- info about employee like job title and birth date

SELECT * FROM Sales.SalesPerson -- bonus and commission and sales of the sales person

SELECT * FROM Sales.SalesTerritory -- info about sales countries

SELECT * FROM Person.CountryRegion

SELECT * FROM Person.StateProvince

--------------------------------------------------


-- the best-performing products by total sales revenue.
SELECT
	Name product_name,
	SUM(OrderQty) total_quantity_sold,
	SUM(LineTotal) total_revnue
FROM
	Sales.SalesOrderDetail s
LEFT JOIN Production.Product p
	ON p.ProductID = s.ProductID
GROUP BY Name
ORDER BY SUM(LineTotal) DESC
--------------------------------------------------



-- Sales Trends Over Time (Monthly Rev)
-- identifying peak seasons for sales
SELECT
	DATETRUNC(MONTH, OrderDate) order_month,
	SUM(LineTotal) total_sales
FROM
	Sales.SalesOrderDetail sod
LEFT JOIN Production.Product p
	ON p.ProductID = sod.ProductID
LEFT JOIN Sales.SalesOrderHeader soh
	ON sod.SalesOrderID = soh.SalesOrderID 
GROUP BY 
	DATETRUNC(MONTH , OrderDate)
ORDER BY order_month
--------------------------------------------------



-- Customer Segmentation by Total Spending
SELECT
	sc.CustomerID,
	CONCAT(FirstName, ' ' , LastName) FullName,
	SUM(LineTotal) AS total_spending
FROM 
	Sales.Customer sc
LEFT JOIN Person.Person p 
	ON p.BusinessEntityID= sc.PersonID
LEFT JOIN Sales.SalesOrderHeader soh
	ON sc.CustomerID= soh.CustomerID
RIGHT JOIN Sales.SalesOrderDetail sod
	ON soh.SalesOrderID= sod.SalesOrderID
GROUP BY sc.CustomerID, CONCAT(FirstName, ' ' , LastName)
ORDER BY total_spending DESC;
-- LIMIT 10; top customers based on total spending.
--------------------------------------------------


-- Employee Sales Performance
SELECT 
	CONCAT(FirstName, ' ' , LastName) FullName,
	SalesYTD,
	SalesLastYear
FROM Sales.SalesPerson sp
JOIN Person.Person p
	ON sp.BusinessEntityID = p.BusinessEntityID

SELECT
	hre.BusinessEntityID AS employee_ID,
	CONCAT(p.FirstName, ' ' , p.LastName) FullName
	,SUM(sod.LineTotal) total_sales
FROM
	Sales.SalesPerson sp
LEFT JOIN Person.Person p
	ON sp.BusinessEntityID = p.BusinessEntityID
LEFT JOIN HumanResources.Employee hre
	ON hre.BusinessEntityID= sp.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh
	ON soh.SalesPersonID = sp.BusinessEntityID
LEFT JOIN Sales.SalesOrderDetail sod
	ON soh.SalesOrderID= sod.SalesOrderID
GROUP BY 
	hre.BusinessEntityID , CONCAT(p.FirstName, ' ' , p.LastName)
ORDER BY total_sales DESC
-- LIMIT 10; the top-performing employees in sales.
-----------------------------------------------------------


--=====================================
-- Sales & Revenue Analysis
--=====================================

--Regional sales performance – Comparing sales

SELECT * FROM Sales.SalesTerritory

SELECT 
	st.TerritoryID,
	st.Name AS country_name,
	SUM(LineTotal) total_sales
FROM Sales.SalesTerritory st
JOIN Sales.SalesOrderHeader soh
	ON soh.TerritoryID = st.TerritoryID
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY st.TerritoryID, st.Name
ORDER BY total_sales;
--------------------------------------------------

-- How Often do Customers Return
SELECT
	customerID,
	COUNT(soh.SalesOrderID) Nr_of_Orders,
	MIN(OrderDate) FirstPurchase,
	MAX(OrderDate) LastPurchase,
	DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) DaysBetweenFirst_Last
FROM
	Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderDetailID = soh.SalesOrderID
GROUP BY CustomerID
ORDER BY Nr_of_Orders DESC
-- Customers with higher OrderCount are repeat buyers.
--------------------------------------------------

-- How Much Customers Spend
SELECT 
	c.CustomerID,
	COUNT(soh.SalesOrderID) AS Nr_of_Orders,
    SUM(soh.TotalDue) AS TotalSpent, -- I used the totaldue from Header not LineTotal from Detail to widen the scope for all products in one order
	CASE  
        WHEN SUM(soh.TotalDue) >= 5000 THEN 'High Value'
        WHEN SUM(soh.TotalDue) BETWEEN 1000 AND 4999 THEN 'Medium Value'
        ELSE 'Low Value'
	END AS CustomerSegment, -- customer segmentation based on spending (easier to be done in a BI tool) (will segment again in the next analysis)
    AVG(soh.TotalDue) AS AvgOrderValue -- Helps identify big spenders vs. low-value buyers
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalSpent DESC;

/*
LineTotal (SalesOrderDetail) vs. TotalDue (SalesOrderHeader)
	- LineTotal is at the line-item level (per product in an order).
	- TotalDue is at the order level (includes all products, taxes, and shipping).
*/
--------------------------------------------------

-- 1.	Sales by promotion or discount impact – 


-- Determine if discounts boost revenue or just reduce profit margins.

WITH Checking_Discount_Impact AS(
SELECT 
	SalesOrderID,
	OrderQty,
	p.ProductID,
	UnitPrice,
	p.StandardCost,
	UnitPrice * OrderQty AS LineTotal_NoDiscount,
	UnitPriceDiscount,
	(UnitPrice * (1 - UnitPriceDiscount)) AS DiscountedPrice,
	(UnitPrice * UnitPriceDiscount * OrderQty) AS DiscountAmount,
	LineTotal,
	LineTotal - (StandardCost * OrderQty) Profit_After_Discount,
	(UnitPrice * OrderQty) - (StandardCost * OrderQty) Profit_No_Discount
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p
	ON sod.ProductID = p.ProductID
WHERE UnitPriceDiscount > 0
)
SELECT 
	*,
	CASE WHEN LineTotal > LineTotal_NoDiscount THEN 'Increases Rev'
		WHEN LineTotal < LineTotal_NoDiscount THEN 'Decreases Rev'
	ElSE 'No Impact'
	END AS DiscountImpactOnRev,
	CASE WHEN Profit_After_Discount > Profit_No_Discount THEN 'Increases Profit'
		WHEN Profit_After_Discount < Profit_No_Discount THEN 'Decreases Profit'
		ElSE 'No Impact'
	END AS DiscountImpactOnProfit
FROM
	Checking_Discount_Impact
ORDER BY DiscountAmount DESC;
-- Revenue impact of discounts
-- Profit impact of discounts (considers costs)
----------------------------------------------------------------





--=====================================
-- Customer Segmentation & Behavior
--=====================================


--	High-value vs. low-value customers – Segment customers based on total spending.

WITH CustomerSpending AS (
    SELECT 
        soh.CustomerID,
        SUM(soh.TotalDue) AS TotalSpending
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
)
SELECT 
    cs.CustomerID,
    cs.TotalSpending,
    CASE 
        WHEN cs.TotalSpending >= 15000 THEN 'High-Value'
        ELSE 'Low-Value'
    END AS CustomerSegment
FROM CustomerSpending cs
ORDER BY cs.TotalSpending DESC;
--------------------------------------------------


--	Customer demographics & sales impact – Find patterns based on age, gender, and location.

SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    a.AddressLine1,
    a.City,
    sp.Name AS State,
    cr.Name AS Country,
	SUM(soh.TotalDue) TotalSpending
FROM Sales.Customer c
LEFT JOIN Person.Person p 
    ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
JOIN Person.Address a 
    ON soh.BillToAddressID = a.AddressID
JOIN Person.StateProvince sp 
    ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr 
    ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY c.CustomerID, p.FirstName, p.LastName, a.AddressLine1, a.City, sp.Name, cr.Name;

--------------------------------------------------

-- Loyal vs. one-time customers – Identify repeat customers and their buying frequency.

SELECT 
	CustomerID,
	MAX(OrderDate) LastOrder,
	DATEDIFF(DAY, MAX(OrderDate), GETDATE()) DaysSinceLastPurchase, -- Lower = More recent = More loyal
	COUNT(DISTINCT SalesOrderID) Nr_of_Orders, -- Loyal customers purchase multiple times.
	SUM(TotalDue) RevFromCustomer -- can use it to segment high value customers (VIPs) 
FROM 
	Sales.SalesOrderHeader
--WHERE OrderDate > '2014-5-1'
GROUP BY CustomerID
HAVING COUNT (DISTINCT SalesOrderID) > 1 AND MAX(OrderDate) > '2014-5-1';
---------------------

-- RFM Analysis (Loyal vs. one-time customers)


WITH RFM_Calculation AS (
SELECT
	CustomerID,
	COUNT(SalesOrderID) AS Frequency,
	DATEDIFF(DAY, MAX(OrderDate), GETDATE()) Recency,
	SUM(TotalDue) MonetaryValue
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
),
RFM_Scores AS (
SELECT 
	CustomerID,
	Frequency,
	Recency,
	MonetaryValue,
	NTILE(4) OVER(ORDER BY Recency DESC) AS R_Score,
	NTILE(4) OVER(ORDER BY Frequency DESC) AS F_Score,
	NTILE(4) OVER(ORDER BY MonetaryValue DESC) AS M_Score
FROM RFM_Calculation
)
SELECT
	*,
	(R_Score + F_Score + M_Score) AS RFM_Total,
	CASE
		WHEN (R_Score + F_Score + M_Score) > 10 THEN 'Loyal VIP'
		WHEN (R_Score + F_Score + M_Score) BETWEEN 7 AND 9 THEN 'Frequent Buyer'
		WHEN (R_Score + F_Score + M_Score) BETWEEN 4 AND 6 THEN 'At Risk'
		ELSE 'Churned Customers'
	END AS CustomerSegment
FROM
	RFM_Scores
ORDER BY RFM_Total DESC;
--------------------------------------------------

--	Customer churn analysis –
-- Finding out why customers stop buying and predict churn risk.


-- Identify Churned Customers
SELECT
	CustomerID,
	MAX(OrderDate) LastPurchaseDate,
	DATEDIFF(DAY, MAX(OrderDate), GETDATE()) DaysSinceLastPurchase ,
	COUNT(DISTINCT SalesOrderID) TotalOrders,
	SUM(TotalDue) TotalSpending,
	CASE WHEN DATEDIFF(DAY, MAX(OrderDate), GETDATE()) > 4000 THEN 'Churned' -- the dataset is old hence the large numbers
		 WHEN DATEDIFF(DAY, MAX(OrderDate), GETDATE()) BETWEEN 1800 AND 4000 THEN 'At Risk'
		 ELSE 'Active'
	END AS ChurnStatus
FROM
	Sales.SalesOrderHeader
GROUP BY CustomerID;

--If orders decline sharply before churn, customers might be losing interest.
SELECT
	YEAR(OrderDate) OrderYear,
	COUNT(DISTINCT SalesOrderID) TotalOrders
FROM
	Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;

------

-- Discount Usage & Churn

-- Do Customers stop buying after discounts disappear
SELECT 
	CustomerID,
	COUNT(DISTINCT sod.SalesOrderID) OrdersWithDiscounts,
	COUNT(DISTINCT soh.SalesOrderID) TotalOrders,
	CASE
		WHEN COUNT(DISTINCT sod.SalesOrderID) = COUNT(DISTINCT soh.SalesOrderID) THEN 'Only Buys With Discounts'
		WHEN COUNT(DISTINCT sod.SalesOrderID) > 0 THEN 'Mixed Behavior'
		ELSE 'Never Uses Discounts'
	END AS DiscountBehavior
FROM 
	Sales.SalesOrderHeader soh
LEFT JOIN Sales.SalesOrderDetail sod
	ON soh.SalesOrderID = sod.SalesOrderID AND sod.UnitPriceDiscount > 0
GROUP BY CustomerID
ORDER BY OrdersWithDiscounts DESC;
--If a customer stops buying when discounts end, they might be price-sensitive.

------

-- Did churned customers buy specific products?

WITH CustomersChurnedStatus AS (
    SELECT
        soh.CustomerID,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
        SUM(soh.TotalDue) AS TotalSpending,
        CASE 
            WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 4000 THEN 'Churned'
            WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) BETWEEN 1800 AND 4000 THEN 'At Risk'
            ELSE 'Active'
        END AS ChurnStatus
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
)
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    COUNT(DISTINCT sod.SalesOrderID) AS TotalOrdersByChurned,
    SUM(sod.OrderQty) AS TotalQuantitySoldToChurned,
    SUM(sod.LineTotal) AS TotalRevenueFromChurned,
    ROUND(100.0 * COUNT(DISTINCT sod.SalesOrderID) / NULLIF((SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderHeader), 0), 2) AS ChurnedPurchasePercentage
FROM CustomersChurnedStatus cc
JOIN Sales.SalesOrderHeader soh ON cc.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE cc.ChurnStatus = 'Churned'
GROUP BY p.ProductID, p.Name
ORDER BY TotalQuantitySoldToChurned DESC;

-- If churned customers mostly bought a few products, maybe those items were discontinued or unsatisfactory.


/*
Top products bought by churned customers -> Do they favor specific products?
Revenue contribution -> Are churned customers important for specific product sales?
Churned Purchase Percentage -> Do churned customers disproportionately buy certain products?
*/
------

-- predict churn based on recency, frequency, and spending trends.
WITH CustomerBehavior AS (
    SELECT 
        c.CustomerID,
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS Recency,
        COUNT(DISTINCT soh.SalesOrderID) AS Frequency,
        SUM(soh.TotalDue) AS MonetaryValue
    FROM Sales.Customer c
    JOIN Sales.SalesOrderHeader soh 
        ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID
)
SELECT 
    CustomerID,
    Recency,
    Frequency,
    MonetaryValue,
    CASE  
        WHEN Recency > 4500 OR (Frequency <= 2 AND MonetaryValue < 5000) THEN 'High Risk of Churn'  
        WHEN Recency BETWEEN 1800 AND 4500 THEN 'At Risk'
        ELSE 'Low Risk'
    END AS ChurnRisk
FROM CustomerBehavior
ORDER BY Recency DESC;
--------------------------------------------------

--=====================================
-- Inventory & Supply Chain Analysis
--=====================================

-- Stock turnover rate –
-- Identify fast-moving and slow-moving products.

---
SELECT * FROM Production.ProductInventory -- Current stock levels
SELECT * FROM Production.Product -- Products details
SELECT * FROM Production.TransactionHistory	 -- Inventory transactions
SELECT * FROM Production.WorkOrder	
SELECT * FROM Sales.SalesOrderDetail -- reflects actual costs
SELECT * FROM Purchasing.PurchaseOrderDetail 
---
/*
Stock turnover calculation should be based on sales, not purchases.
*/

/*
Stock Turnover Ratio = Cost of Goods Sold (COGS) / Average Inventory  
*/

WITH TurnOverCalc AS(
	SELECT 
		p.ProductID,
		p.Name ProductName,
		AVG(pi.Quantity) Avg_Inventory,
		SUM(sod.LineTotal) COGS,
		ROUND(SUM(sod.LineTotal)/ NULLIF(AVG(pi.Quantity),0),2) Stock_Turnover_Ratio
	FROM Sales.SalesOrderDetail sod
	JOIN Production.ProductInventory pi -- to get the quantity in stock
		ON pi.ProductID = sod.ProductID
	JOIN Production.Product p -- to get the name of products
		ON p.ProductID = sod.ProductID
	GROUP BY p.ProductID , p.Name
)

SELECT
	*,
	CASE WHEN Avg_Inventory = 0 THEN NULL
		 WHEN Stock_Turnover_Ratio >= 100 THEN 'Fast-Moving Products'
		 WHEN Stock_Turnover_Ratio < 100 THEN 'Slow-Moving Products'
	END AS Products_Moving_Speed
FROM
	TurnOverCalc
ORDER BY Stock_Turnover_Ratio DESC;
--------------------------------------------------


-- Warehouse performance –
-- Analyze stock availability across different locations.
----
SELECT * FROM Production.ProductInventory -- Current stock levels
SELECT * FROM Production.Product -- Products details
SELECT * FROM Production.Location -- Products details
----

SELECT 
	l.Name Location,
	p.Name ProductName,
	SUM(pi.Quantity) TotalStock, --_in_aLocation,
	COUNT (p.ProductID) UniqueProducts,
    AVG(pi.Quantity) AS AvgStockPerProduct, -- Depending on the level of analysis (not puting productName) The AVG will show different value from the SUM
	-- If some locations hold much more stock than others, this helps identify imbalances.
	CASE 
        WHEN SUM(pi.Quantity) = 0 THEN 'Out of Stock'
        WHEN SUM(pi.Quantity) < 20 THEN 'Low Stock'
        WHEN SUM(pi.Quantity) >= 20 AND SUM(pi.Quantity) < 70 THEN 'Moderate Stock'
        ELSE 'Well-Stocked'
    END AS StockStatus
FROM
	Production.ProductInventory pi
LEFT JOIN Production.Product p
	ON pi.ProductID = p.ProductID
JOIN Production.Location l
	ON l.LocationID = pi.LocationID
GROUP BY l.Name, P.Name;
--------------------------------------------------

-- impact on product availability.
----
--SELECT * FROM Production.WorkOrder
--SELECT * FROM Production.WorkOrderRouting
SELECT * FROM Purchasing.PurchaseOrderHeader
SELECT * FROM Purchasing.PurchaseOrderDetail
SELECT * FROM Purchasing.Vendor -- vendor info
SELECT * FROM Production.ProductInventory
----
-- Supplier performance (vendor delays)  Check if supplier delays impact product availability. 
-- Finding delayed suppliers
SELECT
	v.Name SupplierName,
	poh.OrderDate,
	poh.ShipDate,
	pod.DueDate,
	DATEDIFF(DAY, DueDate, ShipDate) DelayDays,
	CASE 
        WHEN poh.ShipDate > pod.DueDate THEN 'Delayed'
        ELSE 'On Time'
    END AS DeliveryStatus
FROM
	Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.Vendor v
	ON v.BusinessEntityID = poh.VendorID
JOIN Purchasing.PurchaseOrderDetail pod
	ON pod.PurchaseOrderID = poh.PurchaseOrderID
WHERE ShipDate > DueDate;

-- Delays impact on Product availability
SELECT
	v.Name SupplierName,
	p.Name ProductName,
	AVG(pi.Quantity) AvgStock,
	COUNT(DISTINCT pod.PurchaseOrderID) OrdersfromSupplier,
	SUM(CASE WHEN poh.ShipDate > pod.DueDate THEN 1 ELSE 0 END) AS LateDeliveries
FROM
	Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.Vendor v
	ON v.BusinessEntityID = poh.VendorID
JOIN Purchasing.PurchaseOrderDetail pod
	ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Production.Product p
	ON p.ProductID = pod.ProductID
JOIN Production.ProductInventory pi
	ON p.ProductID = pi.ProductID
WHERE ShipDate > DueDate -- filter only on delayed products
GROUP BY v.Name, p.Name; -- it seems there is an issue with these 7 products only
-- HAVING ROUND(100.0 * SUM(CASE WHEN poh.ShipDate > pod.DueDate THEN 1 ELSE 0 END) / COUNT(DISTINCT poh.PurchaseOrderID), 2) > 30 AND AVG(pi.Quantity) < 50 -- There is no high-risk suppliers
------


-- how production delays impact stock availability
WITH ProductionDelays AS (
    SELECT 
        ProductID,
        COUNT(WorkOrderID) AS DelayedOrders,
        AVG(DATEDIFF(DAY, EndDate, DueDate)) AS AvgDelay
    FROM Production.WorkOrder
    WHERE DATEDIFF(DAY, EndDate, DueDate) < 0
    GROUP BY ProductID
),
StockChanges AS (
    SELECT 
        pi.ProductID,
        AVG(pi.Quantity) AS AvgStock,
        MIN(pi.Quantity) AS MinStock,
        MAX(pi.Quantity) AS MaxStock
    FROM Production.ProductInventory pi
    GROUP BY pi.ProductID
)
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    pd.DelayedOrders,
    pd.AvgDelay,
    sc.AvgStock,
    sc.MinStock,
    sc.MaxStock,
    CASE 
        WHEN sc.MinStock < (0.5 * sc.MaxStock) THEN 'Stock Dropped After Delays'
        ELSE 'Stock Not Affected'
    END AS StockImpact -- Checks if stock levels dropped significantly after delays
FROM ProductionDelays pd
JOIN StockChanges sc ON pd.ProductID = sc.ProductID
JOIN Production.Product p ON pd.ProductID = p.ProductID
ORDER BY pd.AvgDelay DESC;
-- customer impact -> then sales delays (maybe another time)
--------------------------------------------------


-- Order fulfillment efficiency – 
-- Measure delivery time and find bottlenecks (long delays in fulfillment).

SELECT * FROM Sales.SalesOrderHeader
SELECT * FROM Sales.SalesOrderDetail

SELECT
	SalesOrderID,
	OrderDate,
	ShipDate,
	DueDate,
	DATEDIFF(Day, OrderDate, ShipDate) ProcessingTime,
	DATEDIFF(Day, ShipDate, DueDate) ShipingDelay -- no negative values so there was no early delivery
FROM Sales.SalesOrderHeader
ORDER BY ProcessingTime DESC;
----

-- Finding bottlenecks
WITH CheckingDelays AS 
(
SELECT
	p.ProductID,
	p.Name ProductName,
	COUNT(sod.SalesOrderID) Nr_of_orders,
	AVG(DATEDIFF(Day, OrderDate, ShipDate)) AvgProcessingTime,
	AVG(DATEDIFF(Day, ShipDate, DueDate)) AvgShipingDelay -- no negative values so there was no early delivery
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p
	ON sod.ProductID = p.ProductID
GROUP BY  p.ProductID, p.Name
-- ORDER BY AvgProcessingTime DESC
)
SELECT 
	*,
	CASE WHEN AvgProcessingTime > 7 THEN 'High Processing Time'
		ELSE 'Small Processing Time'
	END AS ProcessTimeStatus,
	CASE WHEN AvgShipingDelay > 7 THEN 'Slow Fulfillment'
		ELSE 'Good Fulfillment'
	END AS ShipingDelayStatus
FROM CheckingDelays
ORDER BY AvgProcessingTime DESC
--------------------------------------------------

--=====================================
-- Financial & Profitability Analysis
--=====================================

-- Profit margin analysis – 
--Compare revenue vs. cost across different product categories.
----
SELECT * FROM Production.ProductSubcategory
SELECT * FROM Production.ProductCategory
SELECT * FROM Production.Product
SELECT * FROM Production.ProductCostHistory
----
SELECT 
	--p.ProductID,
	--p.Name ProductName,
	pc.Name AS Category,
	SUM(LineTotal) TotalRevenue,
	SUM(pch.StandardCost * sod.OrderQty ) TotalCost, -- better to use the cost from productcosthistory than the product as costs change over time
	ROUND((SUM(TotalDue)- SUM(p.StandardCost * sod.OrderQty)),2) Profit,
	ROUND(100.0 * (SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost)) / NULLIF(SUM(sod.LineTotal), 0), 2) AS ProfitMargin
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
	ON p.ProductID = sod.ProductID
LEFT JOIN Production.ProductCostHistory pch
	ON pch.ProductID = sod.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY --p.ProductID, p.Name,
	pc.Name
ORDER BY ProfitMargin DESC
--------------------------------------------------


-- Return/refund trends – 
--Identify products with the highest return rates.

SELECT * FROM Sales.SalesOrderHeader -- has status # and number 6 stands for canceled so I will use it 
SELECT * FROM Sales.SalesOrderDetail -- contains order quantity and cost

-- there is no returns at the Sales Orders Level
SELECT 
	p.Name ProductID,
	COUNT(DISTINCT sod.SalesOrderID) TotalOrders,
	SUM(sod.OrderQty) TotalSold,
	SUM(CASE WHEN soh.Status = 6 THEN 1 ELSE 0 END) TotalReturns
FROM 
	Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
	ON p.ProductID = sod.ProductID
GROUP BY p.Name
ORDER BY TotalReturns;
--------------------------------------------------

SELECT * FROM Sales.SalesOrderHeader

-- Cost optimization – 
-- Find opportunities to reduce costs without affecting sales.

SELECT * FROM Production.Product ORDER BY StandardCost DESC -- find products with high cost but low sales
SELECT * FROM Production.BillOfMaterials
SELECT * FROM Production.ProductCostHistory ORDER BY StandardCost DESC

-- Reduce Production Costs (find high-cost, low-sales products):
SELECT 
	p.ProductID,
	p.Name ProductName,
	p.StandardCost,
	p.ListPrice,
	SUM(sod.OrderQty) TotalSold,
	StandardCost * SUM(sod.OrderQty) TotalProductCost,
	p.ListPrice* SUM(sod.OrderQty) TotalRev
FROM
	Sales.SalesOrderDetail sod
JOIN Production.Product p
	ON p.ProductID = sod.ProductID
GROUP BY p.ProductID,p.Name , p.StandardCost, p.ListPrice
HAVING  StandardCost * SUM(sod.OrderQty)>  p.ListPrice* SUM(sod.OrderQty)* 0.7 -- where production cost is too high relative to revenue.
ORDER BY TotalProductCost;

-- Reduce Supplier Costs (Finding expensive suppliers)
SELECT 
	v.Name VendorName,
	p.productID,
	pv.AverageLeadTime, -- (supplier delays)
	pod.UnitPrice,
	pod.OrderQty,
	(pod.UnitPrice * pod.OrderQty) TotalCost
FROM 
	Purchasing.PurchaseOrderDetail pod
JOIN Production.Product p
	ON p.ProductID = pod.ProductID
JOIN Purchasing.ProductVendor pv
	ON pv.ProductID = p.ProductID
Join Purchasing.Vendor v
	ON v.BusinessEntityID = pv.BusinessEntityID
ORDER BY TotalCost DESC;

-- I can check Inventory and Logistics Optimization too
--------------------------------------------------

-- Discount efficiency –
-- Analyze whether discounts attract more customers or just reduce profit.

WITH DiscountImpact AS (
    SELECT 
        soh.CustomerID,
        sod.SalesOrderID,
        p.ProductID,
        p.Name AS ProductName,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.OrderQty,
        sod.LineTotal,
        p.StandardCost * sod.OrderQty AS TotalCost,
        (sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS Profit,
        CASE 
            WHEN sod.UnitPriceDiscount > 0 THEN 'With Discount'
            ELSE 'No Discount'
        END AS DiscountCategory
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p ON p.ProductID = sod.ProductID
)
SELECT 
    DiscountCategory,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT SalesOrderID) AS TotalOrders,
    SUM(LineTotal) AS TotalRevenue,
    SUM(TotalCost) AS TotalCost,
    SUM(Profit) AS TotalProfit,
    ROUND(AVG(UnitPriceDiscount) * 100, 2) AS AvgDiscountPercent
FROM DiscountImpact
GROUP BY DiscountCategory;
-- customers with no discounts are overwhelming & dicounts doesn't generate profit
--------------------------------------------------


--=====================================
-- Employee Performance & HR Analytics
--=====================================

-- Sales performance by employee –
-- Identify top-performing salespeople
----
SELECT * FROM HumanResources.Employee -- job title
SELECT * FROM Person.Person -- can get the name from here Customers????
SELECT * FROM Sales.SalesPerson
SELECT * FROM Sales.SalesOrderHeader
----

SELECT
	e.BusinessEntityID,
	p.FirstName + ' ' + P.LastName SalesPersonName,
	e.JobTitle,
	COUNT(SalesOrderID) TotalOrders,
	SUM(TotalDue) TotalRevenue,
	ROUND(AVG(soh.TotalDue), 2) AS AvgOrderValue
FROM
	Sales.SalesOrderHeader soh
JOIN HumanResources.Employee e
	ON e.BusinessEntityID  = soh.SalesPersonID
JOIN Person.Person p
	ON p.BusinessEntityID = e.BusinessEntityID
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName, e.JobTitle
ORDER BY TotalRevenue DESC;
--------------------------------------------------
SELECT * FROM Sales.SalesPerson

-- Commission analysis – 
-- Determine if commission-based incentives boost sales.
SELECT 
	sp.BusinessEntityID,
	p.FirstName + ' ' + P.LastName SalesPersonName,
	-- sp.Bonus,
	SUM(CASE WHEN CommissionPct > 0 THEN 1 ELSE 0 END) ComissionStatus,
	ROUND(SUM(soh.TotalDue),0) TotalRev
From
	Sales.SalesPerson sp
JOIN Person.Person p
	ON p.BusinessEntityID = sp.BusinessEntityID
JOIN Sales.SalesOrderHeader soh
	ON sp.BusinessEntityID  = soh.SalesPersonID
GROUP BY sp.BusinessEntityID, p.FirstName + ' ' + P.LastName 
ORDER BY ComissionStatus;
-- commision based incentive does boost sales
----
-- or much easier
SELECT 
	CASE WHEN CommissionPct > 0 THEN 'With Comission'
		 ELSE 'No Comission' 
	END ComissionStatus,
	COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
	ROUND(SUM(soh.TotalDue),0) TotalRev,
	AVG(soh.TotalDue) AS AvgOrderValue
From
	Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh
	ON sp.BusinessEntityID  = soh.SalesPersonID
GROUP BY CASE WHEN CommissionPct > 0 THEN 'With Comission'
		 ELSE 'No Comission' END
ORDER BY ComissionStatus;
--------------------------------------------------


-- Employee attrition analysis 
-- to prevent employee churn
SELECT 
    e.BusinessEntityID,
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears,
    COUNT(DISTINCT eph.RateChangeDate) AS SalaryChanges,
    CASE 
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) > 5 
             AND COUNT(DISTINCT eph.RateChangeDate) <= 1 THEN 'At Risk'
        WHEN COUNT(DISTINCT eph.RateChangeDate) = 0 THEN 'At Risk'
        ELSE 'Likely Retained'
    END AS ChurnRiskLabel
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName, e.HireDate
ORDER BY TenureYears DESC;



