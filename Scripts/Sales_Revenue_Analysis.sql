
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
	END AS CustomerSegment, -- customer segmentation based on spending (easier to be done in a BI tool)
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

-- 1.	Sales by promotion or discount impact – Determine if discounts boost revenue or just reduce profit margins.


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
SELECT
	st.Name AS CountryName,
    c.customerID,
	COUNT(DISTINCT soh.SalesOrderID) NrofOrders, -- Customers with higher OrderCount are repeat buyers.
    SUM(soh.TotalDue) AS TotalSpent, -- customer segmentation based on spending. (In BI tool)
    AVG(soh.TotalDue) AS AvgOrderValue
	--SUM(LineTotal) total_sales
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c
    ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesTerritory st
    ON st.TerritoryID = soh.TerritoryID
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY 
	st.Name,
    c.customerID;

CREATE VIEW vw_CustomerSalesAnalysis AS


--------------------------------------------------