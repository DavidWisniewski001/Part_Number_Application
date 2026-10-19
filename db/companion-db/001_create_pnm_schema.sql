/*
  001_create_pnm_schema.sql
  OPTIONAL / ON HOLD (see ADR-0003, Q-013).
  For a SEPARATE companion database on the same SQL Server instance only.
  NEVER run this in the AutoCAD Electrical catalog database: extra tables there can
  appear as Catalog Browser categories (docs/research/ACADE_2026_CATALOG_COMPATIBILITY.md).
  Not used by the default zero-footprint mode. Not yet run against any database.
*/
IF SCHEMA_ID(N'pnm') IS NULL EXEC(N'CREATE SCHEMA pnm AUTHORIZATION dbo;');
GO

IF OBJECT_ID(N'pnm.Category', N'U') IS NULL
CREATE TABLE pnm.Category (
    CategoryId        INT IDENTITY(1,1) PRIMARY KEY,
    Prefix            CHAR(3)        NOT NULL CONSTRAINT UQ_Category_Prefix UNIQUE,
    Name              NVARCHAR(100)  NOT NULL,
    Noun              NVARCHAR(40)   NOT NULL,
    Modifier          NVARCHAR(40)   NULL,
    AcadeTable        SYSNAME        NULL,   -- target ACADE catalog table, e.g. 'CR'
    IsActive          BIT            NOT NULL DEFAULT 1
);
GO

IF OBJECT_ID(N'pnm.PartNumberSequence', N'U') IS NULL
CREATE TABLE pnm.PartNumberSequence (
    CategoryId        INT NOT NULL PRIMARY KEY REFERENCES pnm.Category(CategoryId),
    LastNumber        INT NOT NULL DEFAULT 0
);
GO

IF OBJECT_ID(N'pnm.AttributeDefinition', N'U') IS NULL
CREATE TABLE pnm.AttributeDefinition (
    AttributeId       INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId        INT            NOT NULL REFERENCES pnm.Category(CategoryId),
    Name              NVARCHAR(60)   NOT NULL,
    DataType          VARCHAR(10)    NOT NULL CHECK (DataType IN ('Text','Number','Enum','Boolean')),
    Unit              NVARCHAR(10)   NULL,
    AllowedValues     NVARCHAR(MAX)  NULL,   -- JSON array for Enum
    IsRequired        BIT            NOT NULL DEFAULT 0,
    DescOrder         INT            NULL,   -- NULL = not part of description
    ShortOptional     BIT            NOT NULL DEFAULT 0,
    Format            NVARCHAR(60)   NULL,   -- e.g. '{value}{unit} COIL'
    AcadeColumn       SYSNAME        NULL,   -- optional mapping, e.g. 'RATING1'
    CONSTRAINT UQ_AttributeDefinition UNIQUE (CategoryId, Name)
);
GO

IF OBJECT_ID(N'pnm.Manufacturer', N'U') IS NULL
CREATE TABLE pnm.Manufacturer (
    ManufacturerId    INT IDENTITY(1,1) PRIMARY KEY,
    Name              NVARCHAR(60)   NOT NULL CONSTRAINT UQ_Manufacturer_Name UNIQUE,
    AcadeCode         NVARCHAR(30)   NULL,   -- value written to ACADE MANUFACTURER
    Aliases           NVARCHAR(MAX)  NULL    -- JSON array
);
GO

IF OBJECT_ID(N'pnm.Part', N'U') IS NULL
CREATE TABLE pnm.Part (
    PartId            INT IDENTITY(1,1) PRIMARY KEY,
    PartNumber        VARCHAR(20)    NOT NULL CONSTRAINT UQ_Part_PartNumber UNIQUE,
    CategoryId        INT            NOT NULL REFERENCES pnm.Category(CategoryId),
    ManufacturerId    INT            NULL REFERENCES pnm.Manufacturer(ManufacturerId),
    Mpn               NVARCHAR(60)   NULL,
    MpnNormalized     NVARCHAR(60)   NULL,
    ShortDescription  NVARCHAR(40)   NOT NULL,
    LongDescription   NVARCHAR(255)  NULL,
    Status            VARCHAR(10)    NOT NULL DEFAULT 'Draft'
                      CHECK (Status IN ('Draft','InReview','Released','Obsolete','Legacy','Void')),
    SupersededById    INT            NULL REFERENCES pnm.Part(PartId),
    DatasheetUrl      NVARCHAR(400)  NULL,
    CreatedBy         NVARCHAR(128)  NOT NULL DEFAULT SUSER_SNAME(),
    CreatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedBy        NVARCHAR(128)  NULL,
    ModifiedAt        DATETIME2(0)   NULL,
    RowVer            ROWVERSION
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Part_Mfr_Mpn')
CREATE INDEX IX_Part_Mfr_Mpn ON pnm.Part (ManufacturerId, MpnNormalized);
GO

IF OBJECT_ID(N'pnm.PartAttribute', N'U') IS NULL
CREATE TABLE pnm.PartAttribute (
    PartId            INT NOT NULL REFERENCES pnm.Part(PartId),
    AttributeId       INT NOT NULL REFERENCES pnm.AttributeDefinition(AttributeId),
    Value             NVARCHAR(200) NOT NULL,
    PRIMARY KEY (PartId, AttributeId)
);
GO

IF OBJECT_ID(N'pnm.Abbreviation', N'U') IS NULL
CREATE TABLE pnm.Abbreviation (
    Term              NVARCHAR(60) NOT NULL PRIMARY KEY,
    Abbrev            NVARCHAR(20) NOT NULL
);
GO

IF OBJECT_ID(N'pnm.AuditLog', N'U') IS NULL
CREATE TABLE pnm.AuditLog (
    AuditId           BIGINT IDENTITY(1,1) PRIMARY KEY,
    PartId            INT            NULL,
    Action            VARCHAR(30)    NOT NULL,
    Detail            NVARCHAR(MAX)  NULL,   -- JSON before/after
    UserName          NVARCHAR(128)  NOT NULL DEFAULT SUSER_SNAME(),
    At                DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID(N'pnm.SyncLog', N'U') IS NULL
CREATE TABLE pnm.SyncLog (
    SyncId            BIGINT IDENTITY(1,1) PRIMARY KEY,
    PartId            INT            NOT NULL REFERENCES pnm.Part(PartId),
    Target            VARCHAR(10)    NOT NULL,   -- 'ACADE' | 'ERP'
    Succeeded         BIT            NOT NULL,
    Message           NVARCHAR(MAX)  NULL,
    At                DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

/* Issues the next part number for a category and creates the Draft part row atomically. */
CREATE OR ALTER PROCEDURE pnm.usp_IssuePartNumber
    @CategoryId        INT,
    @ShortDescription  NVARCHAR(40),
    @PartNumber        VARCHAR(20) OUTPUT,
    @PartId            INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    DECLARE @Prefix CHAR(3), @Next INT;

    SELECT @Prefix = Prefix FROM pnm.Category WHERE CategoryId = @CategoryId AND IsActive = 1;
    IF @Prefix IS NULL THROW 50001, 'Unknown or inactive category.', 1;

    IF NOT EXISTS (SELECT 1 FROM pnm.PartNumberSequence WITH (UPDLOCK, HOLDLOCK) WHERE CategoryId = @CategoryId)
        INSERT pnm.PartNumberSequence (CategoryId, LastNumber) VALUES (@CategoryId, 0);

    UPDATE pnm.PartNumberSequence WITH (UPDLOCK, HOLDLOCK)
       SET @Next = LastNumber = LastNumber + 1
     WHERE CategoryId = @CategoryId;

    IF @Next > 999999 THROW 50002, 'Part number range exhausted for category.', 1;

    SET @PartNumber = @Prefix + '-' + RIGHT('000000' + CAST(@Next AS VARCHAR(6)), 6);

    INSERT pnm.Part (PartNumber, CategoryId, ShortDescription)
    VALUES (@PartNumber, @CategoryId, @ShortDescription);
    SET @PartId = SCOPE_IDENTITY();

    INSERT pnm.AuditLog (PartId, Action, Detail) VALUES (@PartId, 'IssueNumber', @PartNumber);

    COMMIT;
END;
GO
