/*
================================================
Full Load via Stored Procedure: Creating STPs for Precising the Process of Data Loading 
================================================
Script Purpose:
The purpose of this script is to create STP for the full load of cleaned and transformed data in the silver layer.
================================================
*/

--Full Load

EXEC silver.load_silver;

CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Silver Layer';
		PRINT '================================================';

		PRINT '================================================';
		PRINT 'Leading CRM Tables';
		PRINT '================================================';

		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		PRINT '.. Truncating table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting data into: silver.crm_cust_info'
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

		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';

		-------------------------------------------------------------------

		SET @start_time = GETDATE()
		PRINT '.. Truncating table: silver.prd_info'
		TRUNCATE TABLE silver.prd_info 
		PRINT '>> Inserting data into: silver.prd_info'
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
		FROM bronze.prd_info;
		SET @end_time = GETDATE()

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';

		-------------------------------------------------------------------

		SET @start_time = GETDATE()
		PRINT '.. Truncating table: silver.sales_details'
		TRUNCATE TABLE silver.sales_details
		PRINT '>> Inserting data into: silver.sales_details'
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
		SET @end_time = GETDATE()

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds'

		-------------------------------------------------------------------
		
		PRINT '================================================';
		PRINT 'Leading ERP Tables';
		PRINT '================================================';

		SET @start_time = GETDATE()
		PRINT '.. Truncating table: silver.CUST_AZ12'
		TRUNCATE TABLE silver.CUST_AZ12 
		PRINT '>> Inserting data into: silver.CUST_AZ12'
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
		SET @end_time = GETDATE()

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds'

		-------------------------------------------------------------------

		SET @start_time = GETDATE()
		PRINT '.. Truncating table: silver.LOC_A101'
		TRUNCATE TABLE silver.LOC_A101 
		PRINT '>> Inserting data into: silver.LOC_A101'
		INSERT INTO silver.LOC_A101 (CID, CNTRY)
		SELECT 
		REPLACE(CID, '-', '') CID,
		CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
			 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
			 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
			 ELSE TRIM(CNTRY)
		END AS CNTRY
		FROM bronze.LOC_A101 
		SET @end_time = GETDATE()

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds'

		-------------------------------------------------------------------

		SET @start_time = GETDATE()
		PRINT '.. Truncating table: silver.PX_CAT_G1V2'
		TRUNCATE TABLE silver.PX_CAT_G1V2
		PRINT '>> Inserting data into: silver.PX_CAT_G1V2'
		INSERT INTO silver.PX_CAT_G1V2 (ID, CAT, SUBCAT, MAINTENANCE)
		SELECT
		ID,
		CAT,
		SUBCAT,
		MAINTENANCE
		FROM bronze.PX_CAT_G1V2
		SET @end_time = GETDATE()

		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds'

		END TRY
		BEGIN CATCH
			PRINT '================================================';
			PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
			PRINT 'Error Message' + ERROR_MESSAGE()
			PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR)
			PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR)
			PRINT '================================================';
		END CATCH
END;

-------------------------------------------------------------------

SELECT * FROM silver.crm_cust_info;
SELECT * FROM silver.prd_info;
SELECT * FROM silver.sales_details;
SELECT * FROM silver.LOC_A101;
SELECT * FROM silver.CUST_AZ12;
SELECT * FROM silver.PX_CAT_G1V2;
