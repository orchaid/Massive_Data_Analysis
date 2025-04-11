# AdventureWorks Sales Analysis – SQL + Tableau

##  Conclusion

This project delivers a deep-dive analysis of the **AdventureWorks** sales dataset using SQL and interactive Tableau dashboards. It uncovers strategic insights around product revenue, customer behavior, and employee performance.

**Highlights:**

- **Top Revenue Products**: Identified the highest-grossing items to guide marketing and stocking decisions, and found that the leading product by revenue was `Mountain-200 Black, 38` brought in over $4.4M.
- **High Quantity ≠ High Revenue**: Some products sold in high volumes but underperformed in revenue like `Mountain Tire Tube` — a signal for potential pricing review.

- **Seasonal Sales Patterns**: Clear sales peaks during specific months `March` suggest seasonally timed promotions.
- **Customer Segmentation (RFM)**:
  - **Recency**: Some of the highest-spending customers had not made recent purchases — showing early signs of churn.
  - **Frequency & Monetary**: Frequent and high-spending customers form the core revenue base.
- **Churn Identification**: Customers with no transactions in the last 6 months despite high past engagement were flagged as churned or at-risk.
- **Employee Commission Insights**: A positive relationship exists between commission rates and revenue generated, though with diminishing returns beyond certain thresholds.

Two Tableau dashboards were created to visualize and interact with these insights:

- [Employee Dashboard](https://public.tableau.com/app/profile/amr.alesseily/viz/SupplyFinancialEmployeeAnalysis/EmployeeDashboard)  
- [Sales & Customer Segmentation Dashboard](https://public.tableau.com/app/profile/amr.alesseily/viz/CustomerSegmentationSalesAnalysis_17441167184710/SalesDashboard)

### 📸 Dashboard Screenshots

**Sales & Segmentation Dashboard**  
![Sales Dashboard](/Docs/Images/Sales%20Dash.jpeg)


**Employee Performance Dashboard**  
![Employee Dashboard](/Docs/Images/Employee%20Dash.jpeg)




## 🚧 Challenges

- The AdventureWorks database is highly normalized, requiring multiple JOINs to consolidate product, order, and customer data.
- Profit margin analysis was limited by the lack of cost or unit price data.
- Churn and RFM analysis excluded customers without a linked person profile, leading to partial customer segmentation.



## 🎩 Cool Techniques Used

- **Time Series Analysis**: Aggregated `OrderDate` using `DATETRUNC(MONTH, OrderDate)` to identify trends.
- **RFM Customer Segmentation**:
  - Recency: Date of the last order.
  - Frequency: Number of purchases.
  - Monetary: Total revenue generated.
- **Churn Detection**:
  - Defined churned customers as those inactive for 6+ months.
- **Commission-Based Sales Insights**:
  - Correlated commission percentages with total sales revenue per employee using aggregated metrics from `SalesPerson` and `SalesOrderHeader`.



## 🔍 What Else I Might Have Done

- Integrated product cost data to measure **profitability** instead of just revenue.
- Built a **churn prediction model** using classification algorithms in Python.
- Conducted **market basket analysis** to find product bundling opportunities.
- Expanded dashboards with territory-based filtering and dynamic date controls.


### 🗃️ Data Sources
The analysis was based on the following tables from the AdventureWorks database:
- `Production.Product`
- `Sales.SalesOrderDetail`, `Sales.SalesOrderHeader`
- `Sales.Customer`, `Person.Person`
- `HumanResources.Employee`, `Sales.SalesPerson`
- `Sales.SalesTerritory`, `Person.CountryRegion`, `Person.StateProvince`


### 🛠️ Tools & Technologies
- **SQL Server Management Studio (SSMS)**
- **T-SQL**
- **AdventureWorks Database**
  
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
       +---------------------------+
       |                           |                       
+------v---------+       +---------v-------+    
| vw_DimTerritory|       |  vw_DimProduct  |     
|----------------|       |---------------- |    
| TerritoryID    |       | ProductID       |   
| Name           |       | ProductName     |      
| CountryRegion  |       | ProductNumber   |   
| Group          |       | StandardCost    |      
+----------------+       | ListPrice       |      
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




