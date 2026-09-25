/*
================================================
DDL Script: Create Silver Tables
================================================
Script Purpose:
This script creates tables in the silver schema, dropping existing tables if they already exist.
================================================
*/

IF OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id INT,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(50),
	cst_gndr VARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


IF OBJECT_ID ('silver.prd_info', 'U') IS NOT NULL
DROP TABLE silver.prd_info;
CREATE TABLE silver.prd_info (
	prd_id INT,
	prd_key	VARCHAR(50),
	cat_id VARCHAR(50),
	prd_nm VARCHAR(50),
	prd_cost INT,
	prd_line VARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


IF OBJECT_ID ('silver.sales_details', 'U') IS NOT NULL
DROP TABLE silver.sales_details;
CREATE TABLE silver.sales_details (
	sls_ord_num	VARCHAR(50),
	sls_prd_key	VARCHAR(50),
	sls_cust_id	INT,
	sls_order_dt DATE,
	sls_ship_dt	DATE,
	sls_due_dt DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


IF OBJECT_ID ('silver.CUST_AZ12', 'U') IS NOT NULL
DROP TABLE silver.CUST_AZ12;
CREATE TABLE silver.CUST_AZ12 (
	CID	VARCHAR(50),
	BDATE DATE,
	GEN VARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


IF OBJECT_ID ('silver.LOC_A101', 'U') IS NOT NULL
DROP TABLE silver.LOC_A101;
CREATE TABLE silver.LOC_A101 (
	CID	VARCHAR(50),
	CNTRY VARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


IF OBJECT_ID ('silver.PX_CAT_G1V2', 'U') IS NOT NULL
DROP TABLE silver.PX_CAT_G1V2;
CREATE TABLE silver.PX_CAT_G1V2 (
	ID VARCHAR(50),
	CAT	VARCHAR(50),
	SUBCAT VARCHAR(50),
	MAINTENANCE VARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

SELECT * FROM silver.crm_cust_info;
SELECT * FROM silver.prd_info;
SELECT * FROM silver.sales_details;
SELECT * FROM silver.CUST_AZ12;
SELECT * FROM silver.LOC_A101;
SELECT * FROM silver.PX_CAT_G1V2;
