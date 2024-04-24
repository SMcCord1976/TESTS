
--Declare variables
DECLARE @ServerName VARCHAR(255)
DECLARE @MailSubject VARCHAR(255)
DECLARE @CombinedSubject VARCHAR(255)

--Set variables
SET @ServerName =  @@SERVERNAME
SET @MailSubject = ' Jobs Currently Running'
SET @CombinedSubject = @ServerName + @MailSubject

--Trigger the email with attachment
EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'AMG-WAL-SQL08', --Check Profile Name in Database Mail configuration /* NOTE - Naming the database mail profile as the instance name would eliminate the need for hardcoding of the profile_name variable */
	@recipients = 'stephen.mccord@amg.com; james.keenan@managersinvest.com; timothy.dwyer@managersinvest.com; steven.brusstar@managersinvest.com',
	@query = 'SET NOCOUNT ON EXEC [dba_sp_running_job_check] SET NOCOUNT OFF' ,
	@subject = @CombinedSubject,
	@body = 'Please see the attached text document for a list of SQL Server Agent jobs currently running on the instance.

Regards,
AMG Database Services',
	@attach_query_result_as_file = 1 ;