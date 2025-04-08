
--===============================================
-- Views for Analysis in AdventureWorks Database:
--===============================================
    -- This script creates views for various analytical purposes in the AdventureWorks database.
    -- The created views would be used for visualization and reporting in a BI tool.
    -- The views are designed to be in a star schema format, which is optimal for analytical queries.
--------------------------------------------


--==========================
-- Sales & Revenue Analysis
--==========================
-- Description: This view aggregates sales data by product category and month.
--- this? ---
SELECT
    st.TerritoryID,
	st.Name AS country_name,
    soh.customerID,
    sod.ProductID,
	soh.SalesOrderID AS Nr_of_Orders, -- Customers with higher OrderCount are repeat buyers.
    soh.TotalDue AS TotalSpent, -- customer segmentation based on spending. (In BI tool)
    soh.TotalDue AS AvgOrderValue,
	LineTotal total_sales
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c
    ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesTerritory st
    ON st.TerritoryID = soh.TerritoryID
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID;
-------------


-- in star schema format, we have to create views for each dimension and fact table.
CREATE VIEW vw_FactSales AS
SELECT
    soh.SalesOrderID,
    CONVERT(DATE, soh.OrderDate) OrderDate,
    soh.CustomerID,
    soh.TerritoryID,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal,
    soh.TotalDue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID;


CREATE VIEW vw_Dim_FS_Customer AS
SELECT
    CustomerID,
    PersonID,
    StoreID,
    TerritoryID,
    AccountNumber
FROM Sales.Customer;


CREATE VIEW vw_Dim_FS_Territory AS
SELECT
    TerritoryID,
    Name AS TerritoryName,
    CountryRegionCode
FROM Sales.SalesTerritory;


CREATE VIEW vw_Dim_FS_Product AS
SELECT
    ProductID,
    Name AS ProductName,
    StandardCost,
    ListPrice
FROM Production.Product;
--------------------------------------------




--=================================
-- View For Customer Segmentation
--=================================
-- Description: This view is used to segment customers based on their purchase history and demographics.

--- this? ---
SELECT 
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    a.AddressLine1,
    a.City,
    sp.Name AS State,
    cr.Name AS Country,
    TotalDue,
    SalesOrderID AS OrderCount, -- can be used to segment customers based on their spending.
    CONVERT(DATE, OrderDate), -- to get LastPurchaseDate with MAX function.
    sod.SalesOrderID, --OrdersWithDiscounts (Join based sod.UnitPriceDiscount > 0)
    soh.SalesOrderID, -- TotalOrders with and without discount.
    -- to compare the number of orders when there is a discount and without a discount.
    pr.ProductID,
    pr.Name AS ProductName, -- to get TotalQuantitySoldToChurned, TotalRevenueFromChurned
FROM Sales.SalesOrderHeader
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
JOIN Production.Product pr 
    ON pr.ProductID = sod.ProductID;
-------------


-- in star schema format, we have to create views for each dimension and fact table.
CREATE VIEW vw_FactCustomerOrders AS
SELECT 
    soh.SalesOrderID,
    soh.CustomerID,
    CONVERT(DATE, soh.OrderDate) OrderDate,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal,
    CASE 
        WHEN sod.UnitPriceDiscount > 0 THEN 1
        ELSE 0
    END AS IsDiscounted
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID;


CREATE VIEW vw_Dim_CO_Customer AS
SELECT 
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    a.AddressLine1,
    a.City,
    sp.Name AS State,
    cr.Name AS Country
FROM Sales.Customer c
LEFT JOIN Person.Person p 
    ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
LEFT JOIN Person.Address a 
    ON soh.BillToAddressID = a.AddressID
LEFT JOIN Person.StateProvince sp 
    ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN Person.CountryRegion cr 
    ON sp.CountryRegionCode = cr.CountryRegionCode;


CREATE VIEW vw_Dim_CO_Product AS
SELECT 
    ProductID,
    Name AS ProductName
FROM Production.Product
--------------------------------------------




--=====================================
-- Inventory & Supply Chain Analysis
--=====================================
-- Description: This view provides insights into inventory levels and supply chain performance.


--- this? ---
SELECT
    p.ProductID,
	p.Name ProductName,
    l.Name Location,
    v.Name VendorName,
	poh.OrderDate,
	poh.ShipDate,
	pod.DueDate,
    pi.Quantity AS TotalStock,
    sod.LineTotal,

FROM 
    Production.Product p
JOIN Production.ProductInventory pi
    ON p.ProductID = pi.ProductID
JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
JOIN Production.Location l
	ON l.LocationID = pi.LocationID
JOIN Purchasing.PurchaseOrderDetail pod
	ON pod.ProductID = p.ProductID
JOIN Purchasing.PurchaseOrderHeader poh
    ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v
	ON v.BusinessEntityID = poh.VendorID;
-------------
-- turnover ratio


-- star schema format
CREATE VIEW vw_FactInventoryFlow AS
SELECT 
    p.ProductID,
    pi.LocationID,
    poh.VendorID,
    poh.OrderDate,
    poh.ShipDate,
    pod.DueDate,
    pi.Quantity AS QuantityInStock,
    sod.LineTotal
FROM Production.Product p
JOIN Production.ProductInventory pi
    ON p.ProductID = pi.ProductID
JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
JOIN Production.Location l
    ON pi.LocationID = l.LocationID
JOIN Purchasing.PurchaseOrderDetail pod
    ON pod.ProductID = p.ProductID
JOIN Purchasing.PurchaseOrderHeader poh
    ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v
    ON poh.VendorID = v.BusinessEntityID;



CREATE VIEW vw_Dim_IF_Product AS
SELECT 
    ProductID,
    Name AS ProductName,
    ProductNumber,
    StandardCost,
    ListPrice
FROM Production.Product;



CREATE VIEW vw_Dim_IF_Location AS
SELECT 
    LocationID,
    Name AS LocationName,
    CostRate,
    Availability
FROM Production.Location;


CREATE VIEW vw_Dim_IF_Vendor AS
SELECT 
    v.BusinessEntityID AS VendorID,
    v.Name AS VendorName,
    p.PhoneNumber,
    ea.EmailAddress,
    cr.Name AS Country
FROM Purchasing.Vendor v
LEFT JOIN Person.BusinessEntityContact bec ON bec.BusinessEntityID = v.BusinessEntityID
LEFT JOIN Person.PersonPhone p ON p.BusinessEntityID = bec.PersonID
LEFT JOIN Person.EmailAddress ea ON ea.BusinessEntityID = bec.PersonID
LEFT JOIN Person.StateProvince sp ON sp.StateProvinceID = v.CreditRating
LEFT JOIN Person.CountryRegion cr ON cr.CountryRegionCode = sp.CountryRegionCode;
--------------------------------------------




--=====================================
-- Financial & Profitability Analysis
--=====================================
-- Description: This view provides insights into financial performance and profitability metrics.

--- this? ---
SELECT
    p.ProductID,
    p.Name ProductName,
    pc.name AS Category,
    soh.CustomerID, 
    sod.SalesOrderID,
    sod.UnitPrice,
    sod.UnitPriceDiscount, -- to segments customers based on wether they are price-sensitive or not.
    p.ListPrice,
    sod.OrderQty,
    LineTotal,
	(pch.StandardCost * sod.OrderQty) AS TotalCost,
    (sod.LineTotal - (pch.StandardCost * sod.OrderQty)) AS Profit,
    (sod.LineTotal - (pch.StandardCost * sod.OrderQty)) / sod.LineTotal AS ProfitMargin
    
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
	ON p.ProductID = sod.ProductID
LEFT JOIN Production.ProductCostHistory pch
	ON pch.ProductID = sod.ProductID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID;
-------------
-- Reduce Production Costs (find high-cost, low-sales products):
-- Discount efficiency –


-- star schema format

-- Fact Table: Product Profitability
CREATE VIEW vw_FactProductProfitability AS
SELECT
    sod.SalesOrderID,
    soh.CustomerID,
    p.ProductID,
    pc.ProductCategoryID,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.OrderQty,
    sod.LineTotal,
    (pch.StandardCost * sod.OrderQty) AS TotalCost,
    (sod.LineTotal - (pch.StandardCost * sod.OrderQty)) AS Profit,
    (sod.LineTotal - (pch.StandardCost * sod.OrderQty)) / NULLIF(sod.LineTotal, 0) AS ProfitMargin
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON p.ProductID = sod.ProductID
LEFT JOIN Production.ProductCostHistory pch 
    ON pch.ProductID = sod.ProductID
    AND pch.EndDate IS NULL
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID;



-- Dimension: Product
CREATE VIEW vw_Dim_PP_Product AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ListPrice,
    psc.ProductSubcategoryID,
	psc.ProductCategoryID,
    pch.StandardCost
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCostHistory pch 
    ON p.ProductID = pch.ProductID
    AND pch.EndDate IS NULL; -- Assuming you want the most recent cost


-- Dimension: Category
CREATE VIEW vw_Dim_PP_Category AS
SELECT 
    pc.ProductCategoryID,
    pc.Name AS CategoryName
FROM Production.ProductCategory pc;
--------------------------------------------





--=====================================
-- Employee Performance & HR Analytics
--=====================================
-- Description: This view provides insights into employee performance and HR metrics.

--- this? ---
SELECT
    e.BusinessEntityID,
	p.FirstName + ' ' + P.LastName SalesPersonName,
    e.JobTitle,
	SalesOrderID, -- to get TotalOrders
    soh.TotalDue,
    CASE WHEN CommissionPct > 0 THEN 'With Comission'
		 ELSE 'No Comission' 
	END ComissionStatus, --  for commission analysis
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears, -- to get EmployeeTenure
    CASE 
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) > 5 
             AND COUNT(DISTINCT eph.RateChangeDate) <= 1 THEN 'At Risk'
        WHEN COUNT(DISTINCT eph.RateChangeDate) = 0 THEN 'At Risk'
        ELSE 'Likely Retained'
    END AS ChurnRiskLabel
FROM
	Sales.SalesOrderHeader soh
JOIN HumanResources.Employee e
	ON e.BusinessEntityID  = soh.SalesPersonID
JOIN Person.Person p
	ON p.BusinessEntityID = e.BusinessEntityID
JOIN HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID;
-------------

-- star schema format
-- fact
CREATE VIEW vw_FactEmployeeSales AS
WITH EmployeeChurnData AS (
    SELECT 
        e.BusinessEntityID,
        DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears,
        COUNT(DISTINCT eph.RateChangeDate) AS RateChangeCount
    FROM HumanResources.Employee e
    JOIN HumanResources.EmployeePayHistory eph 
        ON e.BusinessEntityID = eph.BusinessEntityID
    GROUP BY e.BusinessEntityID, e.HireDate
),
ChurnLabeled AS (
    SELECT 
        BusinessEntityID,
        TenureYears,
        RateChangeCount,
        CASE 
            WHEN TenureYears > 5 AND RateChangeCount <= 1 THEN 'At Risk'
            WHEN RateChangeCount = 0 THEN 'At Risk'
            ELSE 'Likely Retained'
        END AS ChurnRiskLabel
    FROM EmployeeChurnData
)
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    e.BusinessEntityID AS EmployeeID,
    soh.TotalDue,
    CASE 
        WHEN sp.CommissionPct > 0 THEN 'With Commission'
        ELSE 'No Commission'
    END AS CommissionStatus,
    cl.RateChangeCount,
    cl.ChurnRiskLabel
FROM Sales.SalesOrderHeader soh
JOIN HumanResources.Employee e 
    ON e.BusinessEntityID = soh.SalesPersonID
JOIN Sales.SalesPerson sp 
    ON soh.SalesPersonID = sp.BusinessEntityID
JOIN ChurnLabeled cl 
    ON cl.BusinessEntityID = e.BusinessEntityID;




-- Dimension: Employee
CREATE VIEW vw_Dim_ES_Employee AS
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName + ' ' + p.LastName AS SalesPersonName,
    e.JobTitle,
    e.HireDate,
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID;
--------------------------------------------