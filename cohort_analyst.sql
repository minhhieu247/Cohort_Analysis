--- have 541909 records
/*
SELECT COUNT(*) AS count FROM [dbo].[Online Retail] */

--- view data
SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [dbo].[Online Retail]
  ORDER BY Quantity,UnitPrice
  
  --- clean data

 WITH Online_Retail as
	( -- 406829 records have customerID
 SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM dbo.[Online Retail]
	  WHERE CustomerID IS NOT NULL
	)
	 
	, quantity_unit_price AS 
	(--- 397884 records with quantity and unitprice
	SELECT *
	FROM Online_Retail 
	WHERE Quantity >0 AND UnitPrice >0
	)
	---duplicate check (windown funtion) - 4 chức năng chính xem lại cheatseat
	, dup_check AS
	(
	SELECT *, 
	ROW_NUMBER() 
	OVER (PARTITION BY quantity_unit_price.InvoiceNo, quantity_unit_price.StockCode, quantity_unit_price.Quantity ORDER BY quantity_unit_price.InvoiceDate)
	AS duplicate
	FROM quantity_unit_price
	)

select *
into #online_retail_main
from dup_check
where dup_check.duplicate = 1
	
	-- 392669 record clean data

-- analyst
--BEGIN COHORT ANALYSIS
SELECT
CustomerID, 
MIN(InvoiceDate) AS first_purchase_date,
DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)),1) AS cohor_date
INTO #cohor
FROM #online_retail_main
GROUP BY CustomerID


SELECT * FROM #cohor
-- create cohort index 
	SELECT mmm.*,
	cohort_index=mmm.year_diff*12 + mmm.month_diff  + 1
	INTO	#cohort_retetion
	FROM
    (
	
			SELECT mm.*,
			year_diff= mm.invoice_year-mm.cohort_year,
			month_diff=mm.invoice_month-mm.corhort_month
			FROM
			(
				SELECT  m.*,
					c.cohor_date,
					YEAR(m.InvoiceDate) AS invoice_year,
					MONTH(m.InvoiceDate) AS invoice_month,
					YEAR(c.cohor_date) AS cohort_year,
					MONTH(c.cohor_date) AS corhort_month
				FROM #online_retail_main AS m 
				LEFT JOIN #cohor  AS c
				ON m.CustomerID=c.CustomerID
			) AS mm
	) AS mmm

	SELECT * FROM #cohort_retetion
	--pivot data the cohort tabel
	SELECT *
	FROM 
	(
	SELECT DISTINCT CustomerID,
	cohor_date,
	cohort_index
    FROM #cohort_retetion
	
	) AS tbl 
PIVOT (
COUNT(CustomerID)
FOR cohort_index IN 
        
		(

		[1], 
        [2], 
        [3], 
        [4], 
        [5], 
        [6], 
        [7],
		[8], 
        [9], 
        [10], 
        [11], 
        [12],
		[13])

     ) AS pivot_table
	ORDER BY pivot_table.cohor_date