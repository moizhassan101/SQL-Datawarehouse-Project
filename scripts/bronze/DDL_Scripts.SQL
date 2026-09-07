/*
============================

DDL Script: Create bronze tables

Script Purpose:
  This script creates tables in the 'bronze' schema, dropping existing tables
  if they already exist
  Run this script to redefine the structure of bronze layer
============================
*/
--Create SQL DDL scripts for all CSV files in the CRM and ERP systems

IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
cst_id INT,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE
);


IF OBJECT_ID ('bronze.prd_info', 'U') IS NOT NULL
DROP TABLE bronze.prd_info;
CREATE TABLE bronze.prd_info (
prd_id INT,
prd_key	VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost INT,
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);


IF OBJECT_ID ('bronze.sales_details', 'U') IS NOT NULL
DROP TABLE bronze.sales_details;
CREATE TABLE bronze.sales_details (
sls_ord_num	VARCHAR(50),
sls_prd_key	VARCHAR(50),
sls_cust_id	INT,
sls_order_dt INT,
sls_ship_dt	INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT
);


IF OBJECT_ID ('bronze.CUST_AZ12', 'U') IS NOT NULL
DROP TABLE bronze.CUST_AZ12;
CREATE TABLE bronze.CUST_AZ12 (
CID	VARCHAR(50),
BDATE DATE,
GEN VARCHAR(50)
);


IF OBJECT_ID ('bronze.LOC_A101', 'U') IS NOT NULL
DROP TABLE bronze.LOC_A101;
CREATE TABLE bronze.LOC_A101 (
CID	VARCHAR(50),
CNTRY VARCHAR(50)
);


IF OBJECT_ID ('bronze.PX_CAT_G1V2', 'U') IS NOT NULL
DROP TABLE bronze.PX_CAT_G1V2;
CREATE TABLE bronze.PX_CAT_G1V2 (
ID VARCHAR(50),
CAT	VARCHAR(50),
SUBCAT VARCHAR(50),
MAINTENANCE VARCHAR(50)
);

SELECT * FROM bronze.crm_cust_info;
SELECT * FROM bronze.prd_info;
SELECT * FROM bronze.sales_details;
SELECT * FROM bronze.CUST_AZ12;
SELECT * FROM bronze.LOC_A101;
SELECT * FROM bronze.PX_CAT_G1V2;
