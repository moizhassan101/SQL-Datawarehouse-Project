================================================
Database Creation: Creating Database "DataWarehouse"
================================================

-- Create databasse "DataWarehouse"

USE master;

CREATE DATABASE DataWarehouse;

use DataWarehouse;

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
