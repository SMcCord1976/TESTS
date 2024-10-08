USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_orphaned_users]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[dba_sp_orphaned_users]

AS

BEGIN



IF NOT EXISTS (select name from sysobjects where name = 'dba_tmp_orphanedusers')
CREATE TABLE [dbo].[dba_tmp_orphanedusers](
	[-- REMAP STATEMENT --] [nvarchar](MAX) NOT NULL,
	[-- SERVER NAME --] [nvarchar](128) NULL,
	[-- INSTANCE NAME --] [nvarchar](128) NULL,
	[-- DATABASE NAME --] [nvarchar](128) NULL,
	[-- TIME STAMP --] [datetime] NOT NULL
) ON [PRIMARY]



DECLARE @command VARCHAR(MAX)

SELECT @command = 'USE ? INSERT INTO spc_dba_utilities.dbo.dba_tmp_orphanedusers
		SELECT   ''ALTER USER ['' + rm.name + ''] WITH LOGIN = ['' + rm.name + '']'' AS [-- REMAP STATEMENT --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 GETDATE() AS [-- TIME STAMP --]
FROM sys.database_principals AS rm
INNER JOIN sys.server_principals AS sp
	ON rm.name = sp.name COLLATE DATABASE_DEFAULT 
	AND rm.sid <> sp.sid
WHERE rm.[type] IN (''U'', ''S'', ''G'', ''E'', ''X'') -- windows users, sql users, windows groups, external users, external groups
	AND rm.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'', ''MS_DataCollectorInternalUser'')'


EXEC sp_MSforeachdb @command



END
GO
