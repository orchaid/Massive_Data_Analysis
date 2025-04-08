  ## Star Schema Diagram for Sales & Revenue
   ```        
                        +----------------------+
                        |   vw_DimCustomer     |
                        |----------------------|
                        | CustomerID (PK)      |
                        | PersonID             |
                        | StoreID              |
                        | TerritoryID          |
                        | AccountNumber        |
                        +----------+-----------+
                                   |
                                   |
                                   |
                        +----------v-----------+
                        |     vw_FactSales     |
                        |----------------------|
                        | SalesOrderID         |
                        | OrderDate            |
                        | CustomerID (FK)      |
                        | TerritoryID (FK)     |
                        | ProductID (FK)       |
                        | OrderQty             |
                        | UnitPrice            |
                        | LineTotal            |
                        | TotalDue             |
                        +----------+-----------+
                                   |
       +---------------------------+---------------------------+
       |                           |                           |
+------v---------+       +---------v-------+        +----------v--------+
| vw_DimTerritory|       |  vw_DimProduct  |        |  (Optional others)|
|----------------|       |---------------- |        |-------------------|
| TerritoryID    |       | ProductID       |        | TimeDim, StoreDim |
| Name           |       | ProductName     |        | etc.              |
| CountryRegion  |       | ProductNumber   |        |                   |
| Group          |       | StandardCost    |        |                   |
+----------------+       | ListPrice       |        +-------------------+
                         +-----------------+
```


```
                            +------------------------+
                            |     vw_DimCustomer     |
                            |------------------------|
                            | CustomerID     (PK)    |
                            | CustomerName           |
                            | AddressLine1           |
                            | City                   |
                            | State                  |
                            | Country                |
                            +-----------+------------+
                                        |
                                        |
                          +-------------v-------------+
                          |    vw_FactCustomerOrders  |
                          |---------------------------|
                          | SalesOrderID              |
                          | OrderDate                 |
                          | CustomerID       (FK)     |
                          | ProductID        (FK)     |
                          | OrderQty                  |
                          | UnitPrice                 |
                          | UnitPriceDiscount         |
                          | LineTotal                 |
                          | IsDiscounted              |
                          +------+------+-------------+
                                 |      |
               +----------------+      +----------------+
               |                                     |
   +-----------v------------+          +-------------v-----------+
   |     vw_DimProduct      |          |       vw_DimDate        |
   |------------------------|          |--------------------------|
   | ProductID       (PK)   |          | Date             (PK)    |
   | ProductName             |         | Year                     |
   | ProductNumber           |         | Month                    |
   | StandardCost            |         | DayOfWeek                |
   | ListPrice               |         | IsWeekend                |
   +------------------------+          +--------------------------+


```

```
                             +-------------------------+
                             |      vw_DimProduct      |
                             |-------------------------|
                             | ProductID       (PK)    |
                             | ProductName             |
                             | ProductNumber           |
                             | StandardCost            |
                             | ListPrice               |
                             +-----------+-------------+
                                         |
                                         |
                             +-----------v-------------+
                             |   vw_FactInventoryFlow  |
                             |-------------------------|
                             | ProductID        (FK)   |
                             | LocationID       (FK)   |
                             | VendorID         (FK)   |
                             | OrderDate               |
                             | ShipDate                |
                             | DueDate                 |
                             | QuantityInStock         |
                             | LineTotal (Sales)       |
                             +------+--------+---------+
                                    |        |
                    +---------------+        +----------------+
                    |                                      |
         +----------v----------+              +-------------v------------+
         |   vw_DimLocation     |              |      vw_DimVendor        |
         |---------------------|              |---------------------------|
         | LocationID    (PK)  |              | VendorID           (PK)   |
         | LocationName        |              | VendorName                |
         | CostRate            |              | Country / Contact Info    |
         +---------------------+              +---------------------------+


```

```
                        +-----------------------------+
                        |     vw_DimProduct           |
                        |-----------------------------|
                        | ProductID (PK)              |
                        | ProductName                 |
                        | ListPrice                   |
                        | ProductSubcategoryID (FK)   |
                        | StandardCost                |
                        +-------------+---------------+
                                      |
                                      |
                     +-------------------------------+
                     |                               |
         +-----------v-----------+         +---------v----------+
         |   vw_DimCategory      |         |   vw_FactProductProfitability  |
         |-----------------------|         |-------------------------------|
         | ProductCategoryID (PK)|         | SalesOrderID (PK)             |
         | CategoryName          |         | CustomerID (FK)               |
         +-----------------------+         | ProductID (FK)                |
                                           | ProductCategoryID (FK)        |
                                           | UnitPrice                     |
                                           | UnitPriceDiscount             |
                                           | OrderQty                      |
                                           | LineTotal                     |
                                           | TotalCost                     |
                                           | Profit                        |
                                           | ProfitMargin                  |
                                           +-------+-----------------------+
                                                   |
                              +--------------------v--------------------+
                              |             vw_DimCustomer              |
                              |------------------------------------------|
                              | CustomerID (PK)                          |
                              | (other optional customer details…)       |
                              +------------------------------------------+

```

```
                        +---------------------------+
                        |      vw_DimEmployee       |
                        |---------------------------|
                        | EmployeeID (PK)           |
                        | SalesPersonName           |
                        | JobTitle                  |
                        | HireDate                  |
                        | TenureYears               |
                        +-------------+-------------+
                                      |
                     +-----------------------------+
                     |       vw_FactSalesEmployeePerformance   |
                     |-----------------------------|
                     | SalesOrderID (PK)           |
                     | EmployeeID (FK)             |
                     | TotalDue                    |
                     | CommissionStatus            |
                     | RateChangeCount             |
                     | ChurnRiskLabel              |
                     +-----------------------------+

```


the views built are for
- Customer Segmentation: Perfect ingredients for churn analysis, RFM, and segmentation modeling 🍰




