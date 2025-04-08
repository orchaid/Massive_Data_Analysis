
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