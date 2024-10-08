USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_windows_login_check]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dba_sp_windows_login_check]
AS
BEGIN

/*********************************************************************************/
/* Name:  dba_sp_windows_login_check                                             */
/* Purpose:  Validate SQL Server Logins against Active Directory Accounts.       */  
/* Check for accounts that have been disabled in AD                              */
/* Author:  S. McCord                                                            */
/*                                                                               */
/* NOTES:  Relies upon function fn_SIDToString, and ADSI LSO to execute.         */
/*********************************************************************************/


	IF OBJECT_ID(N'spc_dba_utilities.dbo.dba_tmp_windowslogincheck', N'U') IS NOT NULL
		DROP TABLE spc_dba_utilities.dbo.dba_tmp_windowslogincheck;

	CREATE TABLE spc_dba_utilities.dbo.dba_tmp_windowslogincheck (
		LoginName SYSNAME NOT NULL
		,ADUserName NVARCHAR(1000) NULL
		,IsDisabled BIT NULL
		);

	DECLARE @DomainName SYSNAME = 'SIERRASPACE';--replace with your DOMAIN name.
	DECLARE @LDAPDC SYSNAME = 'sierraspace.com';--replace with LDAP DC
	DECLARE @LoginName SYSNAME;
	DECLARE @cmd NVARCHAR(max);
	DECLARE @stmt NVARCHAR(1000);

	DECLARE wlct_cursor CURSOR LOCAL FORWARD_ONLY STATIC
	FOR
	SELECT PrincipalName = a.name
		,N'SELECT name, samAccountName, objectSid, userAccountControl 
            FROM ''''LDAP://' + @LDAPDC + N''''' 
            WHERE objectSID = ''''' + dbo.fn_SIDToString(a.sid) + ''''''
	FROM sys.server_principals a
	WHERE a.type_desc = 'WINDOWS_LOGIN'
		AND a.name LIKE @DomainName + N'\%' COLLATE SQL_Latin1_General_CP1_CI_AS
	GROUP BY a.name
		,a.sid
	ORDER BY a.name;

	OPEN wlct_cursor;

	FETCH NEXT
	FROM wlct_cursor
	INTO @LoginName
		,@stmt;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @cmd = N'
DECLARE @IsDisabled bit;
DECLARE @LoginName sysname;
DECLARE @name nvarchar(1000);
SET @LoginName = ''' + @LoginName + N''';
SELECT @IsDisabled = CASE WHEN b.userAccountControl & 0x2 = 0x2 THEN 1 ELSE 0 END 
    , @name = b.name
FROM OPENROWSET(''ADSDSOObject'', ''adsdatasource'', ''' + @stmt + N''') b;
SELECT LoginName = @LoginName, ADUserName = @name, IsDisabled = @IsDisabled;
';

		INSERT INTO spc_dba_utilities.dbo.dba_tmp_windowslogincheck
		EXEC sys.sp_executesql @cmd;

		FETCH NEXT
		FROM wlct_cursor
		INTO @LoginName
			,@stmt;
	END

	CLOSE wlct_cursor;

	DEALLOCATE wlct_cursor;
END
GO
