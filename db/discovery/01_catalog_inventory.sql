/*
  01_catalog_inventory.sql  (READ-ONLY, safe to run on production)
  Run in the AutoCAD Electrical catalog database. Answers research tests T3.1, T4.1 and T4.2.
  Creates nothing and changes nothing.
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- avoid blocking ACADE users

-- T3.1  Family tables: tables that have the core catalog columns, with USER1 type and length
SELECT  c.TABLE_SCHEMA, c.TABLE_NAME,
        c.DATA_TYPE                AS USER1_TYPE,
        c.CHARACTER_MAXIMUM_LENGTH AS USER1_LEN
FROM    INFORMATION_SCHEMA.COLUMNS c
WHERE   c.COLUMN_NAME = 'USER1'
  AND   EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS x
                WHERE x.TABLE_SCHEMA = c.TABLE_SCHEMA AND x.TABLE_NAME = c.TABLE_NAME
                  AND x.COLUMN_NAME = 'CATALOG')
  AND   EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS x
                WHERE x.TABLE_SCHEMA = c.TABLE_SCHEMA AND x.TABLE_NAME = c.TABLE_NAME
                  AND x.COLUMN_NAME = 'MANUFACTURER')
ORDER BY c.TABLE_NAME;

-- Full column list for every table (save the output for docs/ACADE_DATABASE_NOTES.md)
SELECT  TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
FROM    INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- T4.1  How RECNUM / ROWGUID are generated; keys, indexes, triggers
SELECT OBJECT_NAME(object_id) AS TableName, name AS IdentityColumn, seed_value, increment_value
FROM   sys.identity_columns ORDER BY 1;

SELECT OBJECT_NAME(parent_object_id) AS TableName, COL_NAME(parent_object_id, parent_column_id) AS ColumnName,
       definition
FROM   sys.default_constraints ORDER BY 1;

SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName, i.type_desc, i.is_unique, i.is_primary_key
FROM   sys.indexes i
WHERE  OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1 AND i.type > 0
ORDER BY 1, 2;

SELECT OBJECT_NAME(parent_id) AS TableName, name AS TriggerName, is_disabled
FROM   sys.triggers WHERE parent_class = 1 ORDER BY 1;

-- Non-table objects already present (views, procedures, schemas)
SELECT s.name AS SchemaName, o.name, o.type_desc
FROM   sys.objects o JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE  o.is_ms_shipped = 0 AND o.type NOT IN ('U','D','PK','UQ','F','C','TR','IT','S')
ORDER BY o.type_desc, o.name;
