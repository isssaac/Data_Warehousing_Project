--Set source data path variable
:setvar SqlSourceDataPath "C:\Users\naush\project\"

--Set database name
:setvar DatabaseName "Project5504"

--Check if both variables above were created sucessfully
IF '$(SqlSourceDataPath)' IS NULL OR '$(SqlSourceDataPath)' = ''
BEGIN
	RAISERROR(N'The variable SqlSourceDataPath must be defined.', 16, 127) WITH NOWAIT
	RETURN
END;

--Return the number of affected rows
SET NOCOUNT OFF;
GO

USE [master];
GO

-- Drop Database
IF EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = N'$(DatabaseName)')
    DROP DATABASE $(DatabaseName);

-- Create Database
PRINT '';
PRINT '*** Creating Database';
GO

CREATE DATABASE $(DatabaseName);
GO

PRINT '';
PRINT '*** Checking for $(DatabaseName) Database';
/* CHECK FOR DATABASE IF IT DOESN'T EXISTS, DO NOT RUN THE REST OF THE SCRIPT */
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE name = N'$(DatabaseName)')
BEGIN
PRINT '*******************************************************************************************************************************************************************'
+char(10)+'********$(DatabaseName) Database does not exist.  Make sure that the script is being run in SQLCMD mode and that the variables have been correctly set.*********'
+char(10)+'*******************************************************************************************************************************************************************';
END
GO

--Set database properties
ALTER DATABASE $(DatabaseName) 
SET RECOVERY SIMPLE, 
    ANSI_NULLS ON, 
    ANSI_PADDING ON, 
    ANSI_WARNINGS ON, 
    ARITHABORT ON, 
    CONCAT_NULL_YIELDS_NULL ON, 
    QUOTED_IDENTIFIER ON, 
    NUMERIC_ROUNDABORT OFF, 
    PAGE_VERIFY CHECKSUM, 
    ALLOW_SNAPSHOT_ISOLATION OFF;
GO

USE $(DatabaseName);
GO

-- Create tables
PRINT '';
PRINT '*** Creating Tables';
GO


CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] IDENTITY NOT NULL PRIMARY KEY,	
	[DayOfMonth] [int] NOT NULL,
	[MonthOfYear] [int] NOT NULL,
	[CalendarQuarter] [int] NOT NULL,
	[CalendarYear] [int] NOT NULL,	
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimGeography](
	[GeographyKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Country] [varchar](100) NOT NULL,
	[CONTINENT] [varchar](100) NOT NULL,	
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimCountrySize](
	[CountrySizeKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[SizeType] [varchar](100) NOT NULL,	
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[DimLifeExpectancy](
	[LifeExpectancyKey] [int] IDENTITY(0,1) NOT NULL PRIMARY KEY,	
	[LifeSpan] [varchar](100) NOT NULL,
) ON [PRIMARY];
GO

CREATE TABLE [dbo].[FactCovid](
	[DateKey] [int] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[CountrySizeKey] [int] NOT NULL,
	[LifeExpectancyKey] [int] NOT NULL,	
	[NewConfirmedCases] [int] NOT NULL,
	[NewDeaths] [int] NOT NULL,
	[NewRecoveredCases] [int] NOT NULL,	
) ON [PRIMARY];
GO

-- Load data
PRINT '';
PRINT '*** Loading Data';
GO

PRINT 'Loading [dbo].[DimDate]';

BULK INSERT [dbo].[DimDate] FROM '$(SqlSourceDataPath)DimDate.csv'
WITH (
    CHECK_CONSTRAINTS,
    --CODEPAGE='ACP',
	DATAFILETYPE='char',
    FIELDTERMINATOR=',',
    ROWTERMINATOR='\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimGeography]';

BULK INSERT [dbo].[DimGeography] FROM '$(SqlSourceDataPath)DimGeography.csv'
WITH (
    CHECK_CONSTRAINTS,
    --CODEPAGE='ACP',	
	DATAFILETYPE='char',
    FIELDTERMINATOR=',',
    ROWTERMINATOR='\n',
	KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimCountrySize]';

BULK INSERT [dbo].[DimCountrySize] FROM '$(SqlSourceDataPath)DimCountrySize.csv'
WITH (
    CHECK_CONSTRAINTS,
    --CODEPAGE='ACP',	
    DATAFILETYPE='char',
    FIELDTERMINATOR=',',
    ROWTERMINATOR='\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[DimLifeExpectancy]';

BULK INSERT [dbo].[DimLifeExpectancy] FROM '$(SqlSourceDataPath)DimLifeExpectancy.csv'
WITH (
    CHECK_CONSTRAINTS,
    --CODEPAGE='ACP',	
    DATAFILETYPE='char',
    FIELDTERMINATOR=',',
    ROWTERMINATOR='\n',
    KEEPIDENTITY,
    TABLOCK
);

PRINT 'Loading [dbo].[FactCovid]';

BULK INSERT [dbo].[FactCovid] FROM '$(SqlSourceDataPath)FactCovid.csv'
WITH (
    CHECK_CONSTRAINTS,
    --CODEPAGE='ACP',
    DATAFILETYPE='char',
    FIELDTERMINATOR=',',
    ROWTERMINATOR='\n',
    --KEEPIDENTITY,
    TABLOCK
);

--Set FK in FactTable
PRINT '';
PRINT '*** Add relation between fact table foreign keys to Primary keys of Dimensions';
GO

AlTER TABLE FactCovid ADD CONSTRAINT 
FK_DateKey FOREIGN KEY (DateKey)REFERENCES DimDate(DateKey);
AlTER TABLE FactCovid ADD CONSTRAINT 
FK_GeographyKey FOREIGN KEY (GeographyKey)REFERENCES DimGeography(GeographyKey);
AlTER TABLE FactCovid ADD CONSTRAINT 
FK_CountrySizeKey FOREIGN KEY (CountrySizeKey)REFERENCES DimCountrySize(CountrySizeKey);
AlTER TABLE FactCovid ADD CONSTRAINT 
FK_LifeExpectancyKey FOREIGN KEY (LifeExpectancyKey)REFERENCES DimLifeExpectancy(LifeExpectancyKey);
Go