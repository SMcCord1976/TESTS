USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_list_dev_ad_groups]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[dba_sp_list_dev_ad_groups]

AS

BEGIN


/*********************************************************************************/
/* Name:  dba_tmp_list_test_ad_groups                                            */
/* Usage:  EXEC dba_sp_show_windows_group_members                                */
/* Purpose:  Show AD security groups that contain the search string listed       */  
/* Author:  S. McCord                                                            */
/*                                                                               */
/* NOTES:  Relies upon ADSI LSO to execute.                                      */
/* Only returns list of group names.                                             */
/*********************************************************************************/



DROP TABLE IF EXISTS spc_dba_utilities.dbo.dba_tmp_list_dev_ad_groups



declare @sql nvarchar(max)

--dump LDAP results to temp table
set @sql = 'SELECT cn
INTO spc_dba_utilities.dbo.dba_tmp_list_dev_ad_groups
FROM OPENQUERY( ADSI, ''
SELECT cn
FROM ''''LDAP://DC=sierraspace,DC=com ''''WHERE objectCategory = ''''group'''' AND cn = ''''P-SQL*DEV*''''
'' )'

--show query that will be used to generate results (change 'PRINT' to 'EXEC' to simply run the query without displaying it)

EXEC (@sql)


--select * from spc_dba_utilities.dbo.dba_tmp_list_test_ad_groups



END
GO
