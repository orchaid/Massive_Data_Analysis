
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