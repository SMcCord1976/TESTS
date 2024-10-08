USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_show_windows_group_members]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dba_sp_show_windows_group_members] @groupName nvarchar(1024)

AS

BEGIN


/*********************************************************************************/
/* Name:  dba_sp_show_windows_group_members                                      */
/* Usage:  EXEC dba_sp_show_windows_group_members 'R-SPCDBA'                     */
/* Purpose:  Show AD user accounts that are members of AD security group         */  
/* Author:  S. McCord                                                            */
/*                                                                               */
/* NOTES:  Relies upon ADSI LSO to execute.                                      */
/* Only returns user accounts, not nested groups.                                */
/*********************************************************************************/



DROP TABLE IF EXISTS spc_dba_utilities.dbo.dba_tmp_windows_group_check


declare @path nvarchar(1024) = 'DC=sierraspace,DC=com'  --ActiveDirectory services path

declare @groupCN nvarchar(1024) = 'CN=' + @groupName +',' --Keep comma at end of attribute 

/* TOP LEVEL OUs ON sierraspace.com*/
declare @parentOU_1 nvarchar(1024) = 'OU=M365_Synced_Groups,' + @path, @sql nvarchar(max) --attribute order is specified backward (youngest child first)
declare @parentOU_2 nvarchar(1024) = 'OU=M365_Synced_Users,' + @path--Keep comma at the end of the attribute 
declare @parentOU_3 nvarchar(1024) = 'OU=Microsoft Exchange Security Groups,' + @path--Keep comma at the end of the attribute 
declare @parentOU_4 nvarchar(1024) = 'OU=Non_Synced,' + @path--Keep comma at the end of the attribute
declare @parentOU_5 nvarchar(1024) = 'OU=Program Data,' + @path--Keep comma at the end of the attribute
declare @parentOU_6 nvarchar(1024) = 'OU=Servers,' + @path--Keep comma at the end of the attribute
declare @parentOU_7 nvarchar(1024) = 'OU=Staging,' + @path--Keep comma at the end of the attribute
declare @parentOU_8 nvarchar(1024) = 'OU=System,' + @path--Keep comma at the end of the attribute
declare @parentOU_9 nvarchar(1024) = 'OU=Users,' + @path--Keep comma at the end of the attribute
declare @parentOU_10 nvarchar(1024) = 'OU=Workstations,' + @path--Keep comma at the end of the attribute
declare @parentOU_11 nvarchar(1024) = 'OU=Z_Disabled User Accounts,' + @path--Keep comma at the end of the attribute
declare @parentOU_12 nvarchar(1024) = 'OU=Microsoft Exchange System Objects,' + @path--Keep comma at the end of the attribute

/* SECOND LEVEL NESTED OUs WITHIN TOP LEVEL OUs THAT HAVE BEEN DECLARED ABOVE */
declare @subOU_1_1 nvarchar(1024) = 'OU=Distribution Lists,' --Keep comma at the end of the attribute 
declare @subOU_1_2 nvarchar(1024) = 'OU=Mail Enabled Security Groups,' --Keep comma at the end of the attribute 
declare @subOU_1_3 nvarchar(1024) = 'OU=Permission Groups,' --Keep comma at the end of the attribute 
declare @subOU_1_4 nvarchar(1024) = 'OU=Role Groups,' --Keep comma at the end of the attribute 
declare @subOU_1_5 nvarchar(1024) = 'OU=Room Lists,' --Keep comma at the end of the attribute 
declare @subOU_2_1 nvarchar(1024) = 'OU=Administrators,' --Keep comma at the end of the attribute 
declare @subOU_2_2 nvarchar(1024) = 'OU=Test Users,' --Keep comma at the end of the attribute 
declare @subOU_2_3 nvarchar(1024) = 'OU=SNC Users,' --Keep comma at the end of the attribute 
declare @subOU_2_4 nvarchar(1024) = 'OU=Shared Service Accounts,' --Keep comma at the end of the attribute 
declare @subOU_2_5 nvarchar(1024) = 'OU=Shared Mailboxes,' --Keep comma at the end of the attribute 
declare @subOU_2_6 nvarchar(1024) = 'OU=Shared Calendars,' --Keep comma at the end of the attribute 
declare @subOU_2_7 nvarchar(1024) = 'OU=Allow USB Devices,' --Keep comma at the end of the attribute 
declare @subOU_2_8 nvarchar(1024) = 'OU=Room Mailboxes,' --Keep comma at the end of the attribute 
declare @subOU_2_9 nvarchar(1024) = 'OU=Resource Mailboxes,' --Keep comma at the end of the attribute 
declare @subOU_2_10 nvarchar(1024) = 'OU=Contact Objects,' --Keep comma at the end of the attribute 
declare @subOU_2_11 nvarchar(1024) = 'OU=Third Party Users,' --Keep comma at the end of the attribute 
declare @subOU_2_12 nvarchar(1024) = 'OU=SS Use,' --Keep comma at the end of the attribute 
declare @subOU_2_13 nvarchar(1024) = 'OU=Z_Disabled,' --Keep comma at the end of the attribute 
declare @subOU_3_1 nvarchar(1024) = 'OU=Administrators,' --Keep comma at the end of the attribute 
declare @subOU_3_2 nvarchar(1024) = 'OU=Groups,' --Keep comma at the end of the attribute 
declare @subOU_3_3 nvarchar(1024) = 'OU=Service Accounts,' --Keep comma at the end of the attribute 
declare @subOU_3_4 nvarchar(1024) = 'OU=Shared Accounts,' --Keep comma at the end of the attribute 




--generate query referencing variables declared above
set @sql = '
SELECT sAMAccountName, displayName, AdsPath, lastLogon
FROM ''LDAP://' + replace(@path,'''','''''') + '''
WHERE objectCategory = ''Person''
AND objectClass = ''user'' 
AND 
(
memberOf = ''' + replace(@groupCN,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_1_1,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_1_2,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_1_3,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_1_4,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_1_5,'''','''''') + replace(@parentOU_1,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_1,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_2,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_3,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_4,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_5,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_6,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_7,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_8,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_9,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_10,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_11,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_12,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_2_13,'''','''''') + replace(@parentOU_2,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@parentOU_3,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_3_1,'''','''''') + replace(@parentOU_3,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_3_2,'''','''''') + replace(@parentOU_3,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_3_3,'''','''''') + replace(@parentOU_3,'''','''''') +'''
OR memberOf = ''' + replace(@groupCN,'''','''''') + replace(@subOU_3_4,'''','''''') + replace(@parentOU_3,'''','''''') +'''
)
'

--create LDAP query using initialized T-SQL query created above
set @sql = '
SELECT ''' + @groupName + ''' as [GroupName], sAMAccountName, displayName, AdsPath
, case     
    when cast([lastLogon] as bigint) = 0 then null
    else dateadd(mi,(cast([lastlogon] as bigint) / 600000000), cast(''1601-01-01'' as datetime2)) 
  end LastLogon
INTO spc_dba_utilities.dbo.dba_tmp_windows_group_check
FROM OPENQUERY(ADSI, ''' + replace(@sql,'''','''''') + ''')
order by sAMAccountName'

--show query that will be used to generate results (change 'PRINT' to 'EXEC' to simply run the query without displaying it)

EXEC (@sql)


select * from spc_dba_utilities.dbo.dba_tmp_windows_group_check

END
GO
