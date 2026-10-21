<p align="center"> <img src="https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white" /> <img src="https://img.shields.io/badge/Architecture-Medallion_(Bronze/Silver/Gold)-C9A227" /> <img src="https://img.shields.io/badge/Pattern-Star_Schema-2E8B57" /> <img src="https://img.shields.io/badge/License-MIT-blue" /> </p> <h1 align="center">SQL Data Warehouse Project</h1> <p align="center"><b>A SQL Server data warehouse that turns raw CRM + ERP CSV exports into a clean, query-ready star schema — built end-to-end with hand-written DDL, stored procedures, and data-quality checks.</b></p> <p align="center"> · <a href="#-architecture">Architecture</a> · <a href="#-data-model-gold-layer">Data Model</a> · <a href="#-how-to-run-it">How to Run</a> </p>

---

## Overview

This project consolidates sales data from two independent, messy source systems — a **CRM** and an **ERP** — into a single SQL Server data warehouse using a **Bronze → Silver → Gold (Medallion) architecture**. It's the full pipeline: raw ingestion, data cleaning and business-rule enforcement, and a final star schema built for analytics.

Everything here is written by hand in T-SQL: table DDL, `BULK INSERT`-based load procedures, row-level data cleansing logic, and the view layer that produces the final dimensional model.

**What it demonstrates:**
- Designing and implementing a layered warehouse architecture from scratch
- Writing idempotent, re-runnable load procedures (`TRUNCATE` + reload) with timing and error handling
- Diagnosing and fixing real data quality problems (duplicate keys, inconsistent codes, broken date ranges, sales that don't reconcile with quantity × price)
- Building a dimensional (star schema) model with surrogate keys for reporting

---

## Architecture

The warehouse follows the **Medallion architecture**: each layer only reads from the layer below it, and each layer's job gets progressively more refined.

| Layer || Purpose || Load pattern |

| **Bronze** || Raw landing zone — tables mirror the source CSVs exactly, no transformation || Full truncate + `BULK INSERT` via `bronze.load_bronze` |
| **Silver** || Cleaned, deduplicated, standardized, business rules applied, source-system fields reconciled || Full truncate + reload via `silver.load_silver` |
| **Gold** || Business-ready star schema — dimension and fact **views** combining Silver tables || Views (no physical load — always reflects current Silver data) |

---

## Data Model (Gold Layer)

The Gold layer exposes a classic **star schema**: one fact table surrounded by conformed dimensions, each with a `ROW_NUMBER()`-generated surrogate key. The data model's image can be found at the end of the document.

<details>
<summary><b>Interesting modeling decisions (click to expand)</b></summary>

- **`gold.dimension_customers`** resolves gender from two conflicting sources: CRM is treated as the master; if CRM says `'n/a'`, it falls back to the ERP value via `COALESCE`.
- **`gold.dimension_products`** filters out historical product versions with `WHERE prd_end_dt IS NULL`, so the dimension only exposes the *current* version of each product.
- **`gold.fact_sales`** resolves business keys (`sls_cust_id`, `sls_prd_key`) into dimension surrogate keys (`customer_key`, `product_key`) via joins at query time — the fact view has no physical foreign keys, so referential integrity is checked manually (see `tests/`).

</details>

---

## What Each Layer Actually Does

<details>
<summary><b>Bronze — raw ingestion</b></summary>

`scripts/bronze/DDL_Scripts.SQL` creates six tables that mirror the source files exactly (no type cleanup, no renaming):

| Table | Source file | Notes |
|---|---|---|
| `bronze.crm_cust_info` | `source_crm/cust_info.csv` | Customer master |
| `bronze.prd_info` | `source_crm/prd_info.csv` | Product master |
| `bronze.sales_details` | `source_crm/sales_details.csv` | Transaction-level sales |
| `bronze.CUST_AZ12` | `source_erp/CUST_AZ12.csv` | ERP customer demographics |
| `bronze.LOC_A101` | `source_erp/LOC_A101.csv` | ERP customer country |
| `bronze.PX_CAT_G1V2` | `source_erp/PX_CAT_G1V2.csv` | ERP product category reference |

`scripts/bronze/proc_load_bronze.sql` defines **`bronze.load_bronze`**, which truncates and reloads every table via `BULK INSERT`, printing per-table and total load duration, wrapped in `TRY/CATCH`.

</details>

<details>
<summary><b>Silver — cleaning, standardization, business rules</b></summary>

`scripts/silver/Data Transformation & Cleaning.sql` is where most of the engineering actually happens. Highlights:

- **Deduplication** — `crm_cust_info` can have multiple rows per `cst_id`; the load keeps only the most recent record per customer:
  ```sql
  SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
  FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
  ```
- **Code standardization** — raw single-letter codes are expanded into readable values, e.g. `cst_marital_status`: `'S'→'Single'`, `'M'→'Married'`, everything else → `'n/a'` (same pattern for gender and product line).
- **Composite key splitting** — `prd_key` in the source actually encodes two things; it's split into a category code and the real product key:
  ```sql
  SUBSTRING(prd_key, 7, LEN(prd_key))              AS prd_key,
  REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')      AS cat_id
  ```
- **Fixing broken date ranges** — some products have overlapping/incorrect `prd_end_dt` values. The fix recalculates each product's end date as *one day before the next version's start date*, using a window function:
  ```sql
  CAST(DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_nm ORDER BY prd_start_dt)) AS DATE)
  ```
- **Reconciling sales math** — `sales_details` rows where `sales ≠ quantity × price` (or are null/negative) get recalculated rather than dropped, so no transactions are lost:
  ```sql
  CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_price * sls_quantity
       THEN sls_quantity * ABS(sls_price) ELSE sls_sales END
  ```
- **Cross-system key matching** — ERP customer IDs carry a `'NAS'` prefix that CRM keys don't; it's stripped so the two systems join cleanly. ERP country codes (`'DE'`, `'US'`/`'USA'`) are mapped to full country names.

`scripts/silver/Full Load via Stored Procedure.sql` wraps all of this into **`silver.load_silver`** — same truncate/reload + timing + error-handling pattern as the Bronze procedure.

`scripts/silver/Understanding & Exploring the Data.sql` holds the exploratory queries used to spot these issues in the first place.

</details>

<details>
<summary><b>Gold — the business-facing model</b></summary>

`scripts/gold/ddl_gold.sql` creates three views — `gold.dimension_customers`, `gold.dimension_products`, `gold.fact_sales` — described in the image below, following an explicit naming convention (snake_case, English, no reserved words) stated directly in the script's header comments.

</details>

---

## Data Quality Checks

Every transformation in the Silver layer is preceded and followed by validation queries — not just "run and hope":

- Primary-key null/duplicate checks (`GROUP BY ... HAVING COUNT(*) > 1`)
- Whitespace checks (`WHERE col != TRIM(col)`)
- Domain/value checks (`SELECT DISTINCT` on coded columns before and after standardization)
- Referential integrity between `gold.fact_sales` and its dimensions (orphaned fact rows surfaced via `LEFT JOIN ... WHERE dim.key IS NULL`)

Additional standalone checks live in `tests/`.

---

## Repository Structure

```
SQL-Datawarehouse-Project/
├── datasets/                                    # Source CSVs go here (not committed — see Setup)
│   └── placeholder
├── docs/                                        # Architecture notes / diagrams
├── scripts/
│   ├── init_database.sql                        # Creates the DataWarehouse DB + bronze/silver/gold schemas
│   ├── bronze/
│   │   ├── DDL_Scripts.SQL                       # Bronze table definitions
│   │   └── proc_load_bronze.sql                  # bronze.load_bronze — BULK INSERT loader
│   ├── silver/
│   │   ├── DDL Scripts.sql                       # Silver table definitions
│   │   ├── Understanding & Exploring the Data.sql# EDA used to find data issues
│   │   ├── Data Transformation & Cleaning.sql    # Cleaning/standardization logic (see above)
│   │   └── Full Load via Stored Procedure.sql    # silver.load_silver — wraps the cleaning logic
│   └── gold/
│       └── ddl_gold.sql                          # Star schema views (dim_customers, dim_products, fact_sales)
├── tests/                                        # Data quality / validation scripts
├── LICENSE
└── README.md
```

---

## How to Run It

1. **Install prerequisites** — SQL Server (Express is fine) + SQL Server Management Studio (SSMS) or Azure Data Studio.
2. **Supply the source data** — this repo doesn't commit the raw CSVs. Create a `source_crm/` and `source_erp/` folder locally with:
   - `source_crm/`: `cust_info.csv`, `prd_info.csv`, `sales_details.csv`
   - `source_erp/`: `CUST_AZ12.csv`, `LOC_A101.csv`, `PX_CAT_G1V2.csv`
3. **Create the database and schemas**
   ```sql
   -- scripts/init_database.sql
   ```
4. **Build and load Bronze**
   ```sql
   -- scripts/bronze/DDL_Scripts.SQL
   -- scripts/bronze/proc_load_bronze.sql   (update the file paths to match your machine, then:)
   EXEC bronze.load_bronze;
   ```
5. **Build and load Silver**
   ```sql
   -- scripts/silver/DDL Scripts.sql
   -- scripts/silver/Full Load via Stored Procedure.sql  (then:)
   EXEC silver.load_silver;
   ```
6. **Build Gold**
   ```sql
   -- scripts/gold/ddl_gold.sql
   ```
7. **Query it**
   ```sql
   SELECT c.country, SUM(f.sales) AS total_sales
   FROM gold.fact_sales f
   JOIN gold.dimension_customers c ON f.customer_key = c.customer_key
   GROUP BY c.country
   ORDER BY total_sales DESC;
   ```

---

## Data Model
<img width="596" height="633" alt="image" src="https://github.com/user-attachments/assets/78e35c38-a120-42be-8846-de40e0086e93" />

---

## Tech Stack

`Microsoft SQL Server` · `T-SQL` · `SSMS` · `Git`

---

## Author

**Moiz Hassan** — [GitHub](https://github.com/moizhassan101)
