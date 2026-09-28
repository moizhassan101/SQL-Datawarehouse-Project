/*
==========================================================
Creating Views for the Gold Layer
==========================================================
Script Purpose:
The purpose of this script is to create views for the Gold Layer in the data warehouse.
The Gold Layer represents the final dimension and fact tables of the star schema.

Each view performs transformations and combines data from the Silver Layer to produce a
clean, enriched, and business-ready dataset.
==========================================================
*/

USE DataWarehouse;

/*
GENERAL PRINCIPLES:-
- Naming Conventions: Use snake_case, with lowercase letters and underscores (_) to separate words
- Language: Use english for all names
- Avoid Reserved Words: Do not use SQL reserved words as object names
*/

SELECT 
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --crm is the master table here 
	 ELSE COALESCE(ca.gen, 'n/a')
END new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.CUST_AZ12 ca
ON ci.cst_key = ca.CID

--------------------------------------------------------

--Creating View: gold.dimension_customers 
CREATE VIEW gold.dimension_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.CNTRY AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --crm is the master table for gender here 
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.BDATE AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.CUST_AZ12 ca
ON ci.cst_key = ca.CID
LEFT JOIN silver.LOC_A101 la
ON ci.cst_key = la.CID

--------------------------------------------------------

SELECT * FROM gold.dimension_customers;

SELECT DISTINCT gender FROM gold.dimension_customers

--------------------------------------------------------
--Creating View: gold.dimension_products
CREATE VIEW gold.dimension_products AS 
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.CAT AS category,
	pc.SUBCAT AS subcategory,
	pc.MAINTENANCE AS maintenance,
	pn.prd_cost AS product_cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS product_startdate
FROM silver.prd_info pn
LEFT JOIN silver.PX_CAT_G1V2 pc
ON pn.cat_id = pc.ID
WHERE pn.prd_end_dt IS NULL --Filter out all historical data

--------------------------------------------------------

SELECT * FROM gold.dimension_products;

--------------------------------------------------------

--Creating View: gold.fact_sales
CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key AS product_key,
	cu.customer_key AS customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS ship_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.sales_details sd
LEFT JOIN gold.dimension_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dimension_customers cu
ON sd.sls_cust_id = cu.customer_id

SELECT * FROM gold.fact_sales;

--------------------------------------------------------

--Foreign Key Integrity (Dimensions)
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dimension_customers c
ON f.customer_key = c.customer_key
LEFT JOIN gold.dimension_products p
ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
