USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_server_level_role_members]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dba_sp_server_level_role_members]
AS
--SHOW ALL HEAVILY SCRUTINIZED ROLE MEMBERS
BEGIN 

/**************************************************************************************/
/*					dba_sp_server_level_role_members - V1 - 04/2024                   */
/*  Show members of scrutinized server level roles                                    */
/*                                                                                    */
/* USAGE: Requires NO parameters.                                                     */
/* EX:		EXEC [dba_sp_server_level_role_members]                                   */
/**************************************************************************************/

/**************************************************************************************/
/*                  CHANGE LOG                                                        */
/* 20240417 - McCord - Initial release                                                */
/*                                                                                    */
/**************************************************************************************/


--Clean up temp tables from last invocation
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[server_level_role_attestation_TEMP]') AND type in (N'U'))
BEGIN
DROP TABLE [spc_dba_utilities].[dbo].[server_level_role_attestation_TEMP]
END

SELECT NAME AS 'SERVER_LOGIN_NAME' /* THE NAME OF THE USER*/
	,CASE isntname
		WHEN 1 THEN 'WINDOWS OBJECT' 
		WHEN 0 THEN 'SQL AUTHENTICATED LOGIN' 
	 END AS 'LOGIN_ACCOUNT_TYPE' /* IS SERVER_LOGIN_NAME A WINDOWS LOGIN (1) OR SQL LOGIN (0) */
	,CASE isntgroup 
		WHEN 1 THEN 'ACTIVE DIRECTORY / ENTRA ID SECURITY GROUP'
		WHEN 0 THEN 'NO'
	 END AS 'IS_WINDOWS_GROUP' /* IS SERVER_LOGIN_NAME A WINDOWS GROUP (1) (i.e. NOT an individual user) */
	,CASE isntuser 
		WHEN 1 THEN 'INDIVIDUAL WINDOWS ACCOUNT'
		WHEN 0 THEN 'NO'
	 END AS 'IS_WINDOWS_USER' /* IS SERVER_LOGIN_NAME A WINDOWS USER (1) (i.e. NOT a group) */
	,CASE sysadmin
		WHEN 1 THEN 'MEMBER OF sysadmin ROLE'
		WHEN 0 THEN 'NO'
	 END AS 'IS_sysadmin'
	,CASE serveradmin
		WHEN 1 THEN 'MEMBER OF serveradmin ROLE'
		WHEN 0 THEN 'NO'
	 END AS 'IS_serveradmin'
	,CASE processadmin
		WHEN 1 THEN 'MEMBER OF processadmin ROLE'
		WHEN 0 THEN 'NO'
	 END AS 'IS_processadmin'
	,CASE dbcreator
		WHEN 1 THEN 'MEMBER OF dbcreator ROLE'
		WHEN 0 THEN 'NO'
	 END AS 'IS_dbcreator'
	,CASE setupadmin
		WHEN 1 THEN 'MEMBER OF setupadmin ROLE'
		WHEN 0 THEN 'NO'
	 END AS 'IS_setupadmin'
INTO [spc_dba_utilities].[dbo].[server_level_role_attestation_TEMP]
FROM master.dbo.syslogins 
	WHERE (sysadmin = 1  /* MOST HIGHLY SCRUTINIZED ROLE */
		OR serveradmin = 1  /* HEAVILY SCRUTINIZED ROLE */
		OR securityadmin = 1  /* HEAVILY SCRUTINIZED ROLE */
		OR processadmin = 1  /* HEAVILY SCRUTINIZED ROLE */
		OR dbcreator = 1  /* HEAVILY SCRUTINIZED ROLE */
		OR setupadmin = 1)  /* HEAVILY SCRUTINIZED ROLE */
AND NAME NOT LIKE 'NT SERVICE%'
AND NAME NOT LIKE 'NT AUTHORITY%'
AND NAME NOT LIKE '##%'
	ORDER BY LOGIN_ACCOUNT_TYPE, IS_WINDOWS_GROUP, IS_WINDOWS_USER

END
GO
