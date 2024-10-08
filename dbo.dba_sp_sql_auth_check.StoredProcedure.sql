USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_sql_auth_check]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dba_sp_sql_auth_check] 
AS
DROP TABLE IF EXISTS [weekly_sql_auth_check];
SELECT 
@@SERVERNAME AS [ServerInstanceName]
, a.name AS [AccountName]
, b.[hasaccess]
, b.[sysadmin]
, b.[securityadmin]
, c.[PasswordLastSetTime]
, c.[IsMustChange]
, c.[DaysUntilExpiration]
, c.[IsExpired]
, c.[IsLocked]
, c.[LockoutTime]
, c.[BadPasswordCount]
, c.[BadPasswordTime]
, c.[DefaultLanguage]
, c.[DefaultDatabase]
INTO [weekly_sql_auth_check]
FROM sys.sql_logins AS a
JOIN dbo.syslogins AS b
ON a.sid = b.sid
CROSS APPLY dbo.login_properties(a.name) AS c
WHERE a.name NOT LIKE '%#%'
AND a.name != 'sa'
AND a.name != '117968-a1' --SM
AND a.name != '117962-a1' --JG
AND a.name != 'cms_admin' --CMS
;
GO
