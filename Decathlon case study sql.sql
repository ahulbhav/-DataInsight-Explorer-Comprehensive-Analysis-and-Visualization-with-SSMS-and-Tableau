select * from year910
select * from year1011

EXEC sp_rename 'year910.F1', 'Invoice', 'COLUMN'

EXEC sp_rename 'year910.Customer ID', 'Customer_id', 'COLUMN'

EXEC sp_rename 'year1011.Customer ID', 'Customer_id', 'COLUMN'

select InvoiceDate , CAST(InvoiceDate as date) as DateConverted
from year910

alter table year910
add DateConverted date

update year910
set DateConverted = CAST(InvoiceDate as date)

alter table year910
drop column InvoiceDate

alter table year1011
add DateConverted date

update year1011
set DateConverted = CAST(InvoiceDate as date)

alter table year1011
drop column InvoiceDate

ALTER TABLE year910
ALTER COLUMN Invoice NVARCHAR(MAX)

ALTER TABLE year1011
ALTER COLUMN Invoice NVARCHAR(MAX)

ALTER TABLE year910
ALTER COLUMN StockCode NVARCHAR(MAX)

ALTER TABLE year1011
ALTER COLUMN StockCode NVARCHAR(MAX)

With Cte as
(SELECT *,
       ROW_NUMBER() OVER (partition by Invoice, StockCode, Description, Quantity, Price, Customer_id, Country, DateConverted ORDER BY Country) AS rownum
FROM year910)
select *
from cte 
where rownum > 1

select * 
from year910
where [Customer_ID] = 16329 and StockCode = 21491

create table year9101
( Invoice nvarchar(max),
StockCode nvarchar(max),
Description nvarchar(255),
Quantity float,
Price float,
Customer_id float,
Country nvarchar(255),
DateConverted date, 
rownum int
)

Insert into year9101
(Invoice, StockCode, Description, Quantity, Price, Customer_id, Country, DateConverted, rownum)
select 
Invoice, StockCode, description, Quantity, Price, Customer_id, Country, DAteConverted, 
 ROW_NUMBER() OVER (partition by Invoice, StockCode, Description, Quantity, Price, Customer_id, Country, DateConverted ORDER BY Country) AS rownum
 from year910

 select * 
 from year9101

 delete from year9101
 where rownum >=2

alter table year9101
drop column rownum

 create table year10111
( Invoice nvarchar(max),
StockCode nvarchar(max),
Description nvarchar(255),
Quantity float,
Price float,
Customer_id float,
Country nvarchar(255),
DateConverted date, 
rownum int
)

Insert into year10111
(Invoice, StockCode, Description, Quantity, Price, Customer_id, Country, DateConverted, rownum)
select 
Invoice, StockCode, description, Quantity, Price, Customer_id, Country, DAteConverted, 
 ROW_NUMBER() OVER (partition by Invoice, StockCode, Description, Quantity, Price, Customer_id, Country, DateConverted ORDER BY Country) AS rownum
 from year1011

  select * 
 from year10111

 delete from year10111
 where rownum >=2

alter table year10111
drop column rownum

---customer behavior based on the quantity and frequency of purchases. 

WITH CustomerPurchases9101 AS (
    SELECT Customer_id,
           COUNT(*) AS purchase_count,
           SUM(abs(Quantity)) AS total_quantity
    FROM year9101
    GROUP BY Customer_id
),
CustomerPurchases10111 AS (
    SELECT Customer_id,
           COUNT(*) AS purchase_count,
           SUM(abs(Quantity)) AS total_quantity
    FROM year10111
    GROUP BY Customer_id
)
SELECT Customer_id,
       purchase_count,
       total_quantity,
       CASE
           WHEN purchase_count >= 5 AND total_quantity >= 50 THEN 'High-Value and Frequent'
           WHEN purchase_count >= 5 THEN 'Frequent'
           WHEN total_quantity >= 50 THEN 'High-Value'
           ELSE 'Low-Value and Infrequent'
       END AS customer_segment
FROM CustomerPurchases9101
UNION ALL
SELECT Customer_id,
       purchase_count,
       total_quantity,
       CASE
           WHEN purchase_count >= 5 AND total_quantity >= 50 THEN 'High-Value and Frequent'
           WHEN purchase_count >= 5 THEN 'Frequent'
           WHEN total_quantity >= 50 THEN 'High-Value'
           ELSE 'Low-Value and Infrequent'
       END AS customer_segment
FROM CustomerPurchases10111
ORDER BY customer_segment;

--- sales performance across different countries to identify potential markets for expansion or areas requiring targeted marketing efforts.
SELECT Country, ROUND(SUM(total_sales), 2) AS total_sales
FROM (
    SELECT Country, SUM(ABS(Quantity * Price)) AS total_sales
    FROM year9101
    GROUP BY Country
    UNION ALL
    SELECT Country, SUM(ABS(Quantity * Price)) AS total_sales
    FROM year10111
    GROUP BY Country
) AS combined_sales
GROUP BY Country
ORDER BY total_sales DESC;

---performance of individual products based on factors like quantity sold, revenue generated, and customer satisfaction ratings.
SELECT 
    Description,
    SUM(total_quantity_sold) AS total_quantity_sold,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    SUM(total_invoices) AS total_invoices,
    SUM(total_customers) AS total_customers
FROM (
    SELECT 
        Description,
        SUM(Quantity) AS total_quantity_sold,
        ROUND(SUM(Quantity * Price), 2) AS total_revenue,
        COUNT(DISTINCT Invoice) AS total_invoices,
        COUNT(DISTINCT Customer_ID) AS total_customers
    FROM 
        year9101
    GROUP BY 
         Description
    UNION ALL
    SELECT 
        Description,
        SUM(Quantity) AS total_quantity_sold,
        ROUND(SUM(Quantity * Price), 2) AS total_revenue,
        COUNT(DISTINCT Invoice) AS total_invoices,
        COUNT(DISTINCT Customer_ID) AS total_customers
    FROM 
        year10111
    GROUP BY 
         Description
) AS combined_results
GROUP BY 
    Description
ORDER BY 
    total_quantity_sold DESC;

---  customer retention rates and analyze factors influencing customer churn. 
WITH CustomerRetention9101 AS (
    SELECT 
        Customer_ID,
        MIN(DateConverted) AS first_purchase_date,
        MAX(DateConverted) AS last_purchase_date
    FROM 
        year9101
    GROUP BY 
        Customer_ID
),
RetentionData9101 AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) >= 1 THEN 1 ELSE 0 END) AS retained_customers,
        SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) < 1 THEN 1 ELSE 0 END) AS churned_customers,
        CAST(SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) >= 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS retention_rate
    FROM 
        CustomerRetention9101
),
CustomerRetention10111 AS (
    SELECT 
        Customer_ID,
        MIN(DateConverted) AS first_purchase_date,
        MAX(DateConverted) AS last_purchase_date
    FROM 
        year10111
    GROUP BY 
        Customer_ID
),
RetentionData10111 AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) >= 1 THEN 1 ELSE 0 END) AS retained_customers,
        SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) < 1 THEN 1 ELSE 0 END) AS churned_customers,
        CAST(SUM(CASE WHEN DATEDIFF(month, first_purchase_date, last_purchase_date) >= 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS retention_rate
    FROM 
        CustomerRetention10111
)
SELECT 
    SUM(total_customers) AS total_customers,
    SUM(retained_customers) AS retained_customers,
    SUM(churned_customers) AS churned_customers,
    ROUND(AVG(retention_rate),2) AS average_retention_rate
FROM (
    SELECT * FROM RetentionData9101
    UNION ALL
    SELECT * FROM RetentionData10111
) AS CombinedRetentionData;

---  sales trends over different time periods to identify seasonal patterns in purchasing behavior.
SELECT 
    month,
    SUM(total_quantity_sold) AS total_quantity_sold,
    SUM(total_revenue) AS total_revenue
FROM (
    SELECT 
        MONTH(DateConverted) AS month,
        SUM(Quantity) AS total_quantity_sold,
        ROUND(SUM(Quantity * Price),2) AS total_revenue
    FROM 
        year9101
    GROUP BY 
        MONTH(DateConverted)
    UNION ALL
    SELECT 
        MONTH(DateConverted) AS month,
        SUM(Quantity) AS total_quantity_sold,
        ROUND(SUM(Quantity * Price),2) AS total_revenue
    FROM 
        year9101
    GROUP BY 
        MONTH(DateConverted)
) AS CombinedData
GROUP BY 
    month
ORDER BY 
    month;





