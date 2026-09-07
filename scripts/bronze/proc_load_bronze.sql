/*
====================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
====================================

Script Purpose: 
  This load procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions:
  - Truncates the bronze tables before loading data.
  - Uses the 'BULK INSERT' command to load data from CSV files to bronze tables.

*/

EXEC bronze.load_bronze;

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.crm_cust_info;

		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\Arcz\OneDrive\Desktop\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_crm\cust_info.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';
		
		
		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.prd_info;

		BULK INSERT bronze.prd_info
		FROM 'C:\Users\Arcz\OneDrive\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_crm\prd_info.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';


		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.sales_details;

		BULK INSERT bronze.sales_details
		FROM 'C:\Users\Arcz\OneDrive\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_crm\sales_details.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';
		

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';


		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.CUST_AZ12;

		BULK INSERT bronze.CUST_AZ12
		FROM 'C:\Users\Arcz\OneDrive\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_erp\CUST_AZ12.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';


		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.LOC_A101;

		BULK INSERT bronze.LOC_A101
		FROM 'C:\Users\Arcz\OneDrive\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_erp\LOC_A101.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';


		SET @start_time = GETDATE();
		--making the table empty so that there are no duplicates loaded again into an existing table
		TRUNCATE TABLE bronze.PX_CAT_G1V2;

		BULK INSERT bronze.PX_CAT_G1V2
		FROM 'C:\Users\Arcz\OneDrive\Data Eng Bootcamp\Project 1 - SQL Warehouse\source_erp\PX_CAT_G1V2.csv'
		WITH (
		 FIRSTROW = 2,
		 FIELDTERMINATOR = ',',
		 TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '-------------------------';

		SET @batch_end_time = GETDATE();
		PRINT '========================================='
		PRINT 'Loading Bronze Layer is Completed';
		PRINT '    - TOTAL DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '========================================='
		
	
	END TRY
	BEGIN CATCH
		PRINT '========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '========================================='
	END CATCH
END;
