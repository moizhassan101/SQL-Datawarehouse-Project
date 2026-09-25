/*
================================================
Data Transformation and Cleaning Script: Building Silver Layer
================================================
Script Purpose:
The purpose of this script is to build the silver layer by data cleaning and transformations.
*/

--BUILDING SILVER LAYER:-

USE DataWarehouse;

----------------------------------------CLEAN, TRANSFORM AND LOAD | crm_cust_info-------------------------------------------------

--Check for nulls or duplicates in the primary key
--Expectations: No results
SELECT cst_id, COUNT(*) FROM bronze.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL;

-------------------------------------------------------------------

--Check for unwanted spaces
--Expectations: No results
SELECT
cst_id,
cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname NOT LIKE TRIM(cst_firstname)

-------------------------------------------------------------------

--Data Standardization & Consistency
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info

-------------------------------------------------------------------

TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

SELECT 
cst_id,
cst_key,
COALESCE(TRIM(cst_firstname), 'n/a'),
COALESCE(TRIM(cst_lastname), 'n/a'),
CASE 
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
END cst_marital_status,
CASE 
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	ELSE 'n/a'
END cst_gndr,
cst_create_date
FROM (
SELECT
*, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last 
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1

SELECT * FROM silver.crm_cust_info;

-------------------------------------------------------------------
-------------------------------------------------------------------

--Check for nulls or duplicates in the primary key
--Expectations: No results
SELECT cst_id, COUNT(*) FROM silver.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL;

-------------------------------------------------------------------

--Check for unwanted spaces
--Expectations: No results
SELECT
cst_id,
cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname NOT LIKE TRIM(cst_firstname)

SELECT
cst_id,
cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname NOT LIKE TRIM(cst_lastname)

-------------------------------------------------------------------

--Data Standardization & Consistency
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info where cst_id is null


----------------------------------------CLEAN, TRANSFORM AND LOAD | crm_prd_info-------------------------------------------------

--Check for nulls or duplicates in primary key
--Expectation: No results
SELECT
prd_id,
COUNT(*)
FROM bronze.prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-------------------------------------------------------------------

--Check for unwanted spaces
--Expectations: No results
SELECT
prd_nm
FROM bronze.prd_info
WHERE prd_nm != TRIM(prd_nm)

-------------------------------------------------------------------

--Check for nulls or negative numbers
--Expectations: No results
SELECT 
prd_cost
FROM bronze.prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

SELECT * FROM bronze.prd_info

-------------------------------------------------------------------

--Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.prd_info

-------------------------------------------------------------------

--Check for invalid date orders
SELECT 
*
FROM bronze.prd_info
WHERE prd_end_dt < prd_start_dt
--Here there's one problem that the start date is greater than the end date, secodnly the prd_cost between 2007-2011 is 12
--and between 2008-2012 it's 14 so this also needs to be fixed by managing the end date as the next start date va lead function

-------------------------------------------------------------------

INSERT INTO silver.prd_info (
	prd_id,
	prd_key,
	cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT
prd_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_nm ORDER BY prd_start_dt)) AS DATE) AS prd_end_dt
FROM bronze.prd_info

SELECT * FROM silver.prd_info 

-------------------------------------------------------------------

--Check for nulls or duplicates in primary key
--Expectation: No results
SELECT
prd_id,
COUNT(*)
FROM silver.prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-------------------------------------------------------------------

--Check for unwanted spaces
--Expectations: No results
SELECT
prd_nm
FROM silver.prd_info
WHERE prd_nm != TRIM(prd_nm)

-------------------------------------------------------------------

--Check for nulls or negative numbers
--Expectations: No results
SELECT 
prd_cost
FROM silver.prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

SELECT * FROM silver.prd_info

-------------------------------------------------------------------

--Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.prd_info

-------------------------------------------------------------------

--Check for invalid date orders
SELECT 
*
FROM silver.prd_info
WHERE prd_end_dt < prd_start_dt
--OR to check the no. of records
SELECT 
COUNT(*)
FROM silver.prd_info
WHERE prd_end_dt > prd_start_dt OR prd_end_dt IS NULL


----------------------------------------CLEAN, TRANSFORM AND LOAD | sales_details-------------------------------------------------

--Check for invalid date orders
SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101

SELECT 
NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.sales_details
WHERE sls_ship_dt<= 0 
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt> 20500101 
OR sls_ship_dt < 19000101

SELECT 
NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20500101 
OR sls_due_dt < 19000101

-------------------------------------------------------------------

--Check for invalid date orders
SELECT
COUNT(*)
FROM bronze.sales_details
WHERE sls_order_dt < sls_ship_dt AND sls_ship_dt < sls_due_dt AND sls_order_dt < sls_due_dt

-------------------------------------------------------------------

--Check data consistency: between sales, quantity, and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
SELECT DISTINCT
sls_sales AS old_sls_sales ,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_price * sls_quantity
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price 
END AS sls_price
FROM bronze.sales_details
WHERE sls_sales != sls_price * sls_quantity 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0  OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-------------------------------------------------------------------

INSERT INTO silver.sales_details (
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	--sls_order_dt
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) --In SQL server, it's important to first convert to varchar then to date format
	END AS sls_order_dt,
	--sls_ship_dt
	CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- even if there are no errors in sls_ship_dt column but there can be in the future and quality checks are important
	END AS sls_ship_dt,
	--sls_due_dt 
	CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- even if there are no errors in sls_ship_dt column but there can be in the future and quality checks are important
	END AS sls_due_dt,
	--sls_sales 
	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_price * sls_quantity
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	--sls_price
	CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price 
	END AS sls_price
FROM bronze.sales_details
--WHERE sls_ord_num != TRIM(sls_ord_num)
--WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.prd_info)
--WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

-------------------------------------------------------------------

--Check data consistency: between sales, quantity, and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
SELECT DISTINCT
sls_sales,
sls_price,
sls_quantity
FROM silver.sales_details
WHERE sls_sales != sls_price * sls_quantity 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0  OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT * FROM silver.sales_details;


----------------------------------------CLEAN, TRANSFORM AND LOAD | erp_cust_az12-------------------------------------------------

SELECT 
CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
	ELSE CID
END CID,
BDATE,
GEN
FROM bronze.CUST_AZ12
WHERE CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID)) 
	ELSE CID
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

-------------------------------------------------------------------

--Identify out-of-range dates
SELECT DISTINCT
BDATE
FROM bronze.CUST_AZ12
WHERE BDATE < '1924-01-01' OR BDATE > GETDATE()

-------------------------------------------------------------------

--Data standardizatin and consistency
SELECT DISTINCT
GEN,
CASE WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
	 WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END GEN
FROM bronze.CUST_AZ12

-------------------------------------------------------------------

INSERT INTO silver.CUST_AZ12 (cid, bdate, gen)
SELECT
	--CID 
	CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE CID
	END CID,
	--BDATE
	CASE WHEN BDATE > GETDATE() THEN NULL
		ELSE BDATE
	END AS BDATE,
	--GEN
	CASE WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
		WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
		ELSE 'n/a'
	END GEN
FROM bronze.CUST_AZ12

SELECT * FROM silver.CUST_AZ12;

-------------------------------------------------------------------

--Identify out-of-range dates
SELECT DISTINCT
BDATE
FROM silver.CUST_AZ12
WHERE BDATE > GETDATE()

-------------------------------------------------------------------

--Data standardizatin and consistency
SELECT DISTINCT
GEN,
CASE WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
	 WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END GEN
FROM silver.CUST_AZ12


----------------------------------------CLEAN, TRANSFORM AND LOAD | LOC_A101-------------------------------------------------

SELECT * FROM bronze.LOC_A101;

SELECT cst_key FROM silver.crm_cust_info;

--Data standardization and consistency
SELECT DISTINCT
CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
	 ELSE TRIM(CNTRY)
END AS CNTRY
FROM bronze.LOC_A101
ORDER BY CNTRY

-------------------------------------------------------------------

INSERT INTO silver.LOC_A101 (CID, CNTRY)
SELECT 
REPLACE(CID, '-', '') CID,
CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
	 ELSE TRIM(CNTRY)
END AS CNTRY
FROM bronze.LOC_A101 

SELECT * FROM silver.LOC_A101;

-------------------------------------------------------------------

--Data standardization and consistency
SELECT DISTINCT
CNTRY
FROM silver.LOC_A101
ORDER BY CNTRY


----------------------------------------CLEAN, TRANSFORM AND LOAD | PX_CAT_G1V2-------------------------------------------------

SELECT * FROM bronze.PX_CAT_G1V2;

-------------------------------------------------------------------

--Check for unwanted spaces
SELECT * FROM bronze.PX_CAT_G1V2
WHERE CAT != TRIM(CAT)
--WHERE SUBCAT != TRIM(SUBCAT)
--WHERE MAINTENANCE != TRIM(MAINTENANCE)

-------------------------------------------------------------------

--Data standardization and consistency
SELECT DISTINCT 
--CAT
--SUBCAT
--MAINTENANCE
FROM bronze.PX_CAT_G1V2;

-------------------------------------------------------------------

INSERT INTO silver.PX_CAT_G1V2 (ID, CAT, SUBCAT, MAINTENANCE)
SELECT
ID,
CAT,
SUBCAT,
MAINTENANCE
FROM bronze.PX_CAT_G1V2

SELECT * FROM silver.PX_CAT_G1V2
