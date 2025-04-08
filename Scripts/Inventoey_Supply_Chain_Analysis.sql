

--=====================================
-- Inventory & Supply Chain Analysis
--=====================================


---
SELECT * FROM Production.ProductInventory -- Current stock levels
SELECT * FROM Production.Product -- Products details
SELECT * FROM Production.TransactionHistory	 -- Inventory transactions
SELECT * FROM Production.WorkOrder	
SELECT * FROM Sales.SalesOrderDetail -- reflects actual costs
SELECT * FROM Purchasing.PurchaseOrderDetail 
---

-- Stock turnover rate –
-- Identify fast-moving and slow-moving products.
-- This is a measure of how quickly inventory is sold and replaced over a period.

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