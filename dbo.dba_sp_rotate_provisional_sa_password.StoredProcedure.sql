USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_rotate_provisional_sa_password]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --drop procedure dba_sp_rotate_provisional_sa_password
 CREATE PROCEDURE [dbo].[dba_sp_rotate_provisional_sa_password]
 AS
 BEGIN

 SET CONCAT_NULL_YIELDS_NULL OFF

 DECLARE @pwd NVARCHAR(MAX)
 DECLARE @sql NVARCHAR(MAX)

 
 SET @pwd = (SELECT a.[rndm_gen_pw] FROM spc_dba_utilities.dbo.[provisional_sa_log] a 
 INNER JOIN (SELECT MAX([record_id]) AS [max_record_id] 
 FROM spc_dba_utilities.dbo.[provisional_sa_log]) b 
 ON a.[record_id] = b.[max_record_id])

 --SELECT @pwd --DEBUGGING
 
 SET @sql = 'ALTER LOGIN [provisional_sa] WITH PASSWORD=N'+QUOTENAME(@pwd,'''')
 
-- PRINT @sql ----DEBUGGING

 EXEC (@sql) --NEED TO WRAP VARIABLE IN PARENS BECAUSE WITHOUT THEM, SQL ASSUMES VALUE TO BE A STORED PROCEDURE NAME RATHER THAN AN EXECUTABLE STATEMENT

 --EXEC sys.sp_executesql @sql --ALTERNATIVELY, USE sys.sp_executesql STORED PROCEDURE TO EXECUTE THE VARIABLE OUTPUT 

 
--CHECK IF THE MOST RECENT ENTRY IN THE LOG TABLE IS AN AUTO ROTATION.  IF YES, THEN END PROCESS
DECLARE @Requestor NVARCHAR(MAX)

SET @Requestor = (SELECT a.[user_email] FROM spc_dba_utilities.dbo.[provisional_sa_log] a 
 INNER JOIN (SELECT MAX([record_id]) AS [max_record_id] 
 FROM spc_dba_utilities.dbo.[provisional_sa_log]) b 
 ON a.[record_id] = b.[max_record_id])

IF (@Requestor = 'AUTO ROTATE')

BEGIN

	SELECT 'AUTO ROTATION'

END

ELSE 


BEGIN

--IF MOST RECENT ENTRY IN THE LOG TABLE IS AN ACTUAL REQUESTOR, SEND EMAIL TO REQUESTOR WITH CREDENTIALS

--Declare variables
DECLARE @recipients NVARCHAR(MAX)
DECLARE @BCC NVARCHAR(MAX)
DECLARE @ServerName VARCHAR(255)
DECLARE @MailSubject VARCHAR(255)
DECLARE @CombinedSubject VARCHAR(255)
DECLARE @body NVARCHAR(MAX)
DECLARE @expiration VARCHAR(10)
DECLARE @expirationnote VARCHAR(100)

--Set variables
SET @recipients = 
(SELECT a.[user_email] FROM spc_dba_utilities.dbo.[provisional_sa_log] a 
 INNER JOIN (SELECT MAX([record_id]) AS [max_record_id] 
 FROM spc_dba_utilities.dbo.[provisional_sa_log]) b 
 ON a.[record_id] = b.[max_record_id])

SET @BCC = 'r-dba-team@sierraspace.com' 
SET @ServerName =  @@SERVERNAME 
SET @MailSubject = ' credentials will automatically expire at midnight MST on '
SET @expiration = (select convert(varchar(10),getdate(),112)) 
SET @CombinedSubject = @ServerName + @MailSubject + @expiration

SET @body = (SELECT a.[rndm_gen_pw] FROM spc_dba_utilities.dbo.[provisional_sa_log] a 
 INNER JOIN (SELECT MAX([record_id]) AS [max_record_id] 
 FROM spc_dba_utilities.dbo.[provisional_sa_log]) b 
 ON a.[record_id] = b.[max_record_id]) 

--Send email
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'SQLServer'
,@recipients = @recipients
,@blind_copy_recipients = @BCC
--,@recipients = 'stephen.mccord@sierraspace.com' --DEBUGGING
,@subject = @CombinedSubject
,@body = @body
,@body_format ='HTML'


END


END
GO
