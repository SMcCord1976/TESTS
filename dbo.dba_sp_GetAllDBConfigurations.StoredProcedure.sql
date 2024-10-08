USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_GetAllDBConfigurations]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     PROC [dbo].[dba_sp_GetAllDBConfigurations] 
AS

BEGIN


/*

This script will script the role members for all roles on the database.

This is useful for scripting permissions in a development environment before refreshing
development with a copy of production.  This will allow us to easily ensure
development permissions are not lost during a prod to dev restoration. 


Author: Steve Kusen
Modified By:  Steve McCord

Updates:
2022-10-05 v5.1: SM 
2023-05-18 v5.2: SM

Bug Fix
1. Removed duplicate insert statement



Updates:
2023-05-18 v5.2: SM
1. Added spc_dba_utilities database to environment.  Stored procedure housed within
2. Increased ServerName and InstanceName column sizes in log table to accommodate SQLMI names
3. Modified code to house log table in spc_dba_utilities database
4. Various formatting

Update
2022-10-05 v5.1: SM 
1. Created initial lookup table
2. Direction given to create objects on msdb ("Don't want SQLRepo on all the instances")

Updates:
2022-09-16 v5.0: SM Updates for record capturing
1. Modified code to store scripts, server name, instance name, database name, and time stamp
2. Timestamp to be used to demonstrate state of permissions prior to restore.
3. Removed Drop Permissions script to prevent unintentional disruptive changes
4. Log table created on SQLRepo database
	a.  Need to solve for instances that do not have a SQLRepo or other DBAdministrative database.


**NOTE THIS PROC NEEDS TO BE EXECUTED ON THE DATABASE WHOSE PERMISSIONS ARE BEING 'SAVED'**


Updates:
2021-06-10 v4.7: SK updates from various feedback
1. Using SID from AG update noted in his 2020-07-07 update.  SUSER_SNAME([sid]) used instead of SUSER_SNAME([name])
2. Fixed TYPE syntax thanks to Fran4mat
3. Added SQL MI users and groups per suggestion from Dromero22
2020-07-07 v4.6: AG added database owner and fix database_principals that are named differently to AD (use latest name from AD/Windows, not SQL value)
2019-06-10 v4.5:
1. T. Bradley suggested fix for verifying that role permissions and execute rights on new roles included.  
Line 302 updated to include the type R, as:
AND [usr].[type] IN ('G', 'S', 'U', 'R') -- S = SQL user, U = Windows user, G = Windows group

2018-06-06 V4.4:
1. Incorporated bshimonov's suggestion to not create the dbo user since it is unnecessary.

2018-11-06 v4.51: AG added ALTER USER as sp_revokeaccess fails due to a user owning a schema with tables.  Drop fails and requires the SQL user to be remapped
Added commented script section to allow dropping of all user permissions in restored database  
2017-07-10 v4.3: 
I was unable to easily get this into a stored procedure / powershell script, so this update includes the changes/updates noted here:
1. Incorporated Andrew G's updates from previous feedback (Much delayed to being updated on the main script page).  Thanks Andrew!
2. danmeskel2002 recommended a fix for the SID issue for "SQL User without login".   
Changed this line:
SID = '' + CONVERT(varchar(1000), sid) 
to
SID = '' + CONVERT(varchar(1000), sid, 1)

2016-10-31:  AG
1. Added extended stored procedures and system object permissions for master database in OBJECT LEVEL PERMISSIONS area by removing join to sys.objects and using functions instead
2. Added EXISTS check to all statements
3. Added CREATE ROLE before adding principals to roles 

2016-08-25:  AG 1. Remove default database being specified for an AD group user as this option causes a failure on create

2015-08-21:
1. Modified section 3.1 to load to a temp table and populate different users based on an error in 2005/2008 because of the update made for contained databases.  Thanks to Andrew G for pointing that out.
2. Altered section 4.1 to include COLLATE DATABASE_DEFAULT in the join statement.  Thanks to Andrew G and PHXHoward for pointing that out.


2015-06-30: 
1. Re-numbered all sections based on additional updates being added inline.
2. Added sections 8, 8.1; From Eddict, user defined types needed to be added.
3. Added sections 4, 4.1; From nhaberl, for orphaned users mapping (if logins don't exist, they will not be created by this script).
4. Updated section 3.1; From nhaberl, updated to include a default schema of dbo. 



*/

/***************************************************************************//***************************************************************************
/* Delete existing users in database (so that they can be recreated with different permissions) */
USE [' + DB_NAME() +']
DECLARE @UserName nvarchar(256)
DECLARE csrUser CURSOR FOR
SELECT [name] FROM sys.database_principals WHERE principal_id > 4 AND is_fixed_role < 1 ORDER BY [name]

OPEN csrUser FETCH NEXT FROM csrUser INTO @UserName WHILE @@FETCH_STATUS <> -1
BEGIN
BEGIN TRY
  EXEC sp_revokedbaccess @UserName
END TRY
BEGIN CATCH
  ROLLBACK
END CATCH
FETCH NEXT FROM csrUser INTO @UserName
END

CLOSE csrUser DEALLOCATE csrUser
***************************************************************************//***************************************************************************/
print ''


/*Prep statements*/
IF NOT EXISTS (select * from spc_dba_utilities..sysobjects where name = 'log_DatabaseConfigurations') 
CREATE TABLE spc_dba_utilities.dbo.log_DatabaseConfigurations
(stmt varchar(max)
, result_order decimal(4,1)
, ServerName [varchar] (max) NULL
, InstanceName [varchar] (max) NULL
, DatabaseName [varchar] (50) NULL
, ConfigType [int] NULL
, [TimeStamp] [datetime] NOT NULL)
IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY('productversion')), 1, charindex('.',convert(sysname, SERVERPROPERTY('productversion')))-1)) > 10)
EXEC ('
INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations 
(stmt
, result_order
, ServerName
, InstanceName
, DatabaseName
, ConfigType
, TimeStamp)
SELECT 
CASE WHEN [type] IN (''U'', ''S'', ''G'')
THEN
      CASE WHEN rm.authentication_type IN (2, 0) /* 2=contained database user with password, 0 =user without login; create users without logins*/ 
       THEN (''IF NOT EXISTS (SELECT SUSER_SNAME([sid]) 
	   FROM sys.database_principals 
	   WHERE SUSER_SNAME([sid]) = '' + SPACE(1) + '''''''' + SUSER_SNAME([sid]) + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME(SUSER_SNAME([sid])) + '' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '' + QUOTENAME([default_schema_name]) + SPACE(1) + '', SID = '' + CONVERT(varchar(1000), sid, 1) + SPACE(1) + '' END; '')
         ELSE 
	  CASE WHEN rm.name = ''dbo'' /* dbo "name" can be different to Windows User */      
	   THEN ''ALTER AUTHORIZATION ON DATABASE::'' + QUOTENAME(DB_NAME()) + '' TO '' + QUOTENAME(SUSER_SNAME([sid])) + '';''
		 ELSE (''IF NOT EXISTS (SELECT SUSER_SNAME([sid]) FROM sys.database_principals WHERE SUSER_SNAME([sid]) = '' + SPACE(1) + '''''''' + SUSER_SNAME([sid]) + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME(SUSER_SNAME([sid])) + '' FOR LOGIN '' + QUOTENAME(SUSER_SNAME([sid])) 
  + CASE WHEN [type] <>''G'' THEN '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL([default_schema_name], ''dbo'')) 
     ELSE '''' 

END + SPACE(1) + ''END ELSE ALTER USER '' + SPACE(1) + QUOTENAME(SUSER_SNAME([sid])) + '' WITH LOGIN = '' + QUOTENAME(SUSER_SNAME([sid])) + '';'') 

END
  
END
WHEN [type] IN (''E'', ''X'')
THEN  
CASE WHEN rm.authentication_type IN (2, 0) /* 2=contained database user with password, 0 =user without login; create users without logins*/ 
       THEN (''IF NOT EXISTS (SELECT SUSER_SNAME([sid]) FROM sys.database_principals WHERE SUSER_SNAME([sid]) = '' + SPACE(1) + '''''''' + SUSER_SNAME([sid]) + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME(SUSER_SNAME([sid])) + '' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '' + QUOTENAME([default_schema_name]) + SPACE(1) + '', SID = '' + CONVERT(varchar(1000), sid, 1) + SPACE(1) + '' END; '')
         ELSE 
   CASE WHEN rm.name = ''dbo'' /* dbo "name" can be different to Windows User */      
    THEN ''ALTER AUTHORIZATION ON DATABASE::'' + QUOTENAME(DB_NAME()) + '' TO '' + QUOTENAME(SUSER_SNAME([sid])) + '';''
    ELSE (''IF NOT EXISTS (SELECT SUSER_SNAME([sid]) FROM sys.database_principals WHERE SUSER_SNAME([sid]) = '' + SPACE(1) + '''''''' + SUSER_SNAME([sid]) + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME(SUSER_SNAME([sid])) + '' FOR LOGIN '' + QUOTENAME(SUSER_SNAME([sid])) 
  + CASE 
     WHEN [type] <>''G'' 
	 THEN '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL([default_schema_name], ''dbo'')) 
     ELSE '''' 

END + SPACE(1) + ''END;'') 
           
END

END

END AS [-- SQL STATEMENTS --],
         3.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
   FROM   sys.database_principals AS rm
   WHERE [type] IN (''U'', ''S'', ''G'', ''E'', ''X'') /* windows users, sql users, windows groups, external users, external groups */     
   AND NAME NOT IN (''guest'')')

ELSE IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY('productversion')), 1, charindex('.',convert(sysname, SERVERPROPERTY('productversion')))-1)) IN (9,10))
EXEC ('
INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
      SELECT   (''IF NOT EXISTS (SELECT SUSER_SNAME([sid]) FROM sys.database_principals WHERE [name] = '' + SPACE(1) + '''''''' + [name] + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME([name]) + '' FOR LOGIN '' + QUOTENAME(suser_sname([sid])) + CASE WHEN [type] <>''G'' THEN '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL([default_schema_name], ''dbo'')) ELSE '''' END + SPACE(1) + ''END ELSE ALTER USER '' + SPACE(1) + QUOTENAME([name]) + '' WITH LOGIN = '' + QUOTENAME(suser_sname([sid])) + '';'')
 AS [-- SQL STATEMENTS --],
         3.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
   FROM   sys.database_principals AS rm
   WHERE [type] IN (''U'', ''S'', ''G'') /* windows users, sql users, windows groups */   AND NAME NOT IN (''guest'',''dbo'')')


DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 
	,@srv VARCHAR(max)
	,@inst VARCHAR(max)
	,@db VARCHAR(50)
	,@cfgtype INT
	,@time DATETIME

DECLARE tmp CURSOR FOR



/*********************************************//*********   DB CONTEXT STATEMENT    *********//*********************************************/

SELECT   'SCRIPT FOR ALL PERMISSIONS ON' + SPACE(1) + QUOTENAME(DB_NAME()) + SPACE(1) + 'SAVED TO spc_dba_utilities.dbo.log_DatabaseConfigurations TABLE' AS [-- SQL STATEMENTS --],
      1.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]

UNION

SELECT '' AS [-- SQL STATEMENTS --],
      2 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		GETDATE() AS [-- TIME STAMP --]



--/*********************************************//*********     DB USER CREATION      *********//*********************************************/
--/********************************************  DISABLED ALONG WITH DROP USER COMMAND ABOVE  ************************************************/
--
--INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
--   SELECT   
--      [stmt],
--         3.1 AS [-- RESULT ORDER HOLDER --],
--		 @@SERVERNAME AS [-- SERVER NAME --],
--		 @@SERVICENAME AS [-- INSTANCE NAME --],
-- 		 DB_NAME() AS [-- DATABASE NAME --],
--		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
--		 GETDATE() AS [-- TIME STAMP --]
--   FROM  spc_dba_utilities.dbo.log_DatabaseConfigurations
--   --WHERE [type] IN ('U', 'S', 'G') -- windows users, sql users, windows groups
--   WHERE [stmt] IS NOT NULL



/*********************************************//*********    DB SCHEMA CREATION    *********//*********************************************/


INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF SCHEMA_ID(' + QUOTENAME([name],'''') COLLATE database_default + ') IS NULL' + SPACE(1) + 'EXEC (' + '''' + 'CREATE SCHEMA'
   + SPACE(1) + QUOTENAME([name]) +
   '''' + ')',
      3.51 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM sys.schemas
WHERE [name] not in (
/*exclude built-in schemas*/'dbo',
'guest',
'INFORMATION_SCHEMA',
'sys',
'Logging',
'db_owner',
'db_accessadmin',
'db_securityadmin',
'db_ddladmin',
'db_backupoperator',
'db_datareader',
'db_datawriter',
'db_denydatareader',
'db_denydatawriter'
)
--ORDER BY [name] ASC




/*********************************************//*********    MAP ORPHANED USERS     *********//*********************************************/


INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'ALTER USER [' + rm.name + '] WITH LOGIN = [' + rm.name + ']',
      4.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM   sys.database_principals AS rm
 Inner JOIN sys.server_principals as sp
 ON rm.name = sp.name COLLATE DATABASE_DEFAULT and rm.sid <> sp.sid
WHERE rm.[type] IN ('U', 'S', 'G', 'E', 'X') -- windows users, sql users, windows groups, external users, external groups
 AND rm.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'MS_DataCollectorInternalUser')



/*********************************************//*********    DB ROLE PERMISSIONS    *********//*********************************************/


INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME([name],'''') COLLATE database_default + ') IS NULL' + SPACE(1) + 'CREATE ROLE'
   + SPACE(1) + QUOTENAME([name]),
      5.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM sys.database_principals
WHERE [type] ='R' -- R = Role
   AND [is_fixed_role] = 0
AND [name] NOT IN ('public','dbo','guest','INFORMATION SCHEMA','sys')
--ORDER BY [name] ASC
--UNION

INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(USER_NAME(rm.member_principal_id),'''') COLLATE database_default + ') IS NOT NULL' + SPACE(1) + 'EXEC sp_addrolemember @rolename ='
   + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''') COLLATE database_default + ', @membername =' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''') COLLATE database_default AS [-- SQL STATEMENTS --],
      5.2 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM   sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) IN (   
                                    --get user names on the database
                                    SELECT [name]
                                    FROM sys.database_principals
                                    WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
                                    and [type] IN ('G', 'S', 'U', 'E', 'X') -- S = SQL user, U = Windows user, G = Windows group, E = external user, X = external group
                                   )
--ORDER BY rm.role_principal_id ASC






/*********************************************//*********  OBJECT LEVEL PERMISSIONS *********//*********************************************/

INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(USER_NAME(usr.principal_id),'''') COLLATE database_default + ') IS NOT NULL' + SPACE(1) +
      CASE 
         WHEN perm.state <> 'W' THEN perm.state_desc 
         ELSE 'GRANT'
      END
      + SPACE(1) + perm.permission_name + SPACE(1) + 'ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(perm.major_id)) + '.' + QUOTENAME(OBJECT_NAME(perm.major_id)) --select, execute, etc on specific objects
      + CASE
            WHEN cl.column_id IS NULL THEN SPACE(0)
            ELSE '(' + QUOTENAME(cl.name) + ')'
        END
      + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
      + CASE 
            WHEN perm.state <> 'W' THEN SPACE(0)
            ELSE SPACE(1) + 'WITH GRANT OPTION'
        END
         AS [-- SQL STATEMENTS --],
      7.2 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM   
   sys.database_permissions AS perm

   /* No join to sys.objects as it excludes system objects such as extended stored procedures */   /*   INNER JOIN
   sys.objects AS obj
         ON perm.major_id = obj.[object_id]
   */      INNER JOIN
   sys.database_principals AS usr
         ON perm.grantee_principal_id = usr.principal_id
      LEFT JOIN
   sys.columns AS cl
         ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
  WHERE /* Include System objects when scripting permissions for master, exclude elsewhere */      (    DB_NAME() <> 'master' AND perm.major_id IN (SELECT [object_id] FROM sys.objects WHERE type NOT IN ('S'))
        OR DB_NAME() =  'master'
        ) 
                      
      
         
--WHERE   usr.name = @OldUser
--ORDER BY perm.permission_name ASC, perm.state_desc ASC




/*********************************************//*********  TYPE LEVEL PERMISSIONS *********//*********************************************/


INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT  'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(USER_NAME(usr.principal_id),'''') COLLATE database_default + ') IS NOT NULL' + SPACE(1) +
      CASE 
            WHEN perm.state <> 'W' THEN perm.state_desc 
            ELSE 'GRANT'
        END
        + SPACE(1) + perm.permission_name + SPACE(1) + 'ON TYPE::' + QUOTENAME(SCHEMA_NAME(tp.schema_id)) + '.' + QUOTENAME(tp.name) --select, execute, etc on specific objects
        + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
        + CASE 
                WHEN perm.state <> 'W' THEN SPACE(0)
                ELSE SPACE(1) + 'WITH GRANT OPTION'
          END
            AS [-- SQL STATEMENTS --],
        8.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]

FROM    
    sys.database_permissions AS perm
        INNER JOIN
    sys.types AS tp
            ON perm.major_id = tp.user_type_id
        INNER JOIN
    sys.database_principals AS usr
            ON perm.grantee_principal_id = usr.principal_id





/*********************************************//*********    DB LEVEL PERMISSIONS   *********//*********************************************/


INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(USER_NAME(usr.principal_id),'''') COLLATE database_default + ') IS NOT NULL' + SPACE(1) +
      CASE 
         WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
         ELSE 'GRANT'
      END
   + SPACE(1) + perm.permission_name --CONNECT, etc
   + SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(usr.principal_id) + ']' COLLATE database_default --TO <user name>
   + CASE 
         WHEN perm.state <> 'W' THEN SPACE(0) 
         ELSE SPACE(1) + 'WITH GRANT OPTION' 
     END
      AS [-- SQL STATEMENTS --],
      10.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
FROM   sys.database_permissions AS perm
   INNER JOIN
   sys.database_principals AS usr
   ON perm.grantee_principal_id = usr.principal_id
--WHERE   usr.name = @OldUser

WHERE   [perm].[major_id] = 0
   AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
   AND [usr].[type] IN ('G', 'S', 'U', 'R', 'E', 'X') -- S = SQL user, U = Windows user, G = Windows group, E = external user, X = external group


/*****************************************//************     SCHEMA LEVEL PERMISSIONS     ***********//************************************/

INSERT INTO spc_dba_utilities.dbo.log_DatabaseConfigurations (stmt, result_order, ServerName, InstanceName, DatabaseName, ConfigType, TimeStamp)
SELECT   'IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(USER_NAME(grantee_principal_id),'''') COLLATE database_default + ') IS NOT NULL' + SPACE(1) +
         CASE
         WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
         ELSE 'GRANT'
         END
            + SPACE(1) + perm.permission_name --CONNECT, etc
            + SPACE(1) + 'ON' + SPACE(1) + class_desc + '::' COLLATE database_default --TO <user name>
            + QUOTENAME(SCHEMA_NAME(major_id))
            + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE database_default
            + CASE
               WHEN perm.state <> 'W' THEN SPACE(0)
               ELSE SPACE(1) + 'WITH GRANT OPTION'
               END
         AS [-- SQL STATEMENTS --],
      12.1 AS [-- RESULT ORDER HOLDER --],
		 @@SERVERNAME AS [-- SERVER NAME --],
		 @@SERVICENAME AS [-- INSTANCE NAME --],
 		 DB_NAME() AS [-- DATABASE NAME --],
		 1 AS [-- CONFIG TYPE --], --ConfigType 1 = Permission, ConfigType 2 = Orphaned Users - lookup table pending
		 GETDATE() AS [-- TIME STAMP --]
from sys.database_permissions AS perm
   inner join sys.schemas s
      on perm.major_id = s.schema_id
   inner join sys.database_principals dbprin
      on perm.grantee_principal_id = dbprin.principal_id
WHERE class = 3 --class 3 = schema

ORDER BY [-- RESULT ORDER HOLDER --]


OPEN tmp
FETCH NEXT FROM tmp INTO @sql, @sort, @srv, @inst, @db, @cfgtype, @time
WHILE @@FETCH_STATUS = 0
BEGIN
        PRINT @sql
        FETCH NEXT FROM tmp INTO @sql, @sort, @srv, @inst, @db, @cfgtype, @time    
END

CLOSE tmp
DEALLOCATE tmp 



DELETE FROM spc_dba_utilities.dbo.log_DatabaseConfigurations
WHERE stmt IS NULL


END



GO
