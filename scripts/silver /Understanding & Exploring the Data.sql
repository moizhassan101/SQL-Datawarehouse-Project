/*
================================================
Data Exploration: Getting the knowledge about the Data
================================================
Script Purpose:
The purpose of this script is to get a better understanding of the data and explore the datasets.
================================================
*/
  
SELECT TOP (1000) [cst_id]
      ,[cst_key]
      ,[cst_firstname]
      ,[cst_lastname]
      ,[cst_marital_status]
      ,[cst_gndr]
      ,[cst_create_date]
  FROM [DataWarehouse].[bronze].[crm_cust_info]

  SELECT TOP (1000) [CID]
      ,[BDATE]
      ,[GEN]
  FROM [DataWarehouse].[bronze].[CUST_AZ12]

  SELECT TOP (1000) [CID]
      ,[CNTRY]
  FROM [DataWarehouse].[bronze].[LOC_A101]

SELECT TOP (1000) [prd_id]
      ,[prd_key]
      ,[prd_nm]
      ,[prd_cost]
      ,[prd_line]
      ,[prd_start_dt]
      ,[prd_end_dt]
  FROM [DataWarehouse].[bronze].[prd_info]

  SELECT TOP (1000) [ID]
      ,[CAT]
      ,[SUBCAT]
      ,[MAINTENANCE]
  FROM [DataWarehouse].[bronze].[PX_CAT_G1V2]

  SELECT TOP (1000) [sls_ord_num]
      ,[sls_prd_key]
      ,[sls_cust_id]
      ,[sls_order_dt]
      ,[sls_ship_dt]
      ,[sls_due_dt]
      ,[sls_sales]
      ,[sls_quantity]
      ,[sls_price]
  FROM [DataWarehouse].[bronze].[sales_details]
