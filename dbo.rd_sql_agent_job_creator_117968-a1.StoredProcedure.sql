USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[rd_sql_agent_job_creator_117968-a1]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[rd_sql_agent_job_creator_117968-a1] @StagingJobSubmitter VARCHAR(MAX), @DeploymentJobDate VARCHAR(50)
AS

BEGIN 

/**************************************************************************************/
/*					rd_sql_agent_job_creator - V1 - 04/2018                           */
/* Makes a functional copy of existing Code Staging job                               */
/*	 Renames / dates job name                                                         */
/*	 Changes job owner from submitter to release engineer                             */
/*                                                                                    */
/* USAGE: Requires 2 parameters.  Submitter (developer) account name, deployment date */
/* EX:		EXEC [rd_sql_agent_job_creator_adm_smccord] 'AMG-HQ\smccord', '20180416'  */
/**************************************************************************************/

/**************************************************************************************/
/*                  CHANGE LOG                                                        */
/* 20180723 - McCord                                                                  */
/* 20190605 - McCord                                                                  */
/* Simplified job names to conform to one standard                                    */
/* Note that AMG-HQ\adm-jbaptista is no longer a valid release engineer               */
/* Added AMG-HQ\adm-nbrandon                                                          */
/* 20230505 - McCord - modified for use at SPC                                        */
/* Added SIERRASPACE\117968-adm                                                       */
/* Added SIERRASPACE\117968-a1                                                        */
/* Added SIERRASPACE\117962-a1                                                        */
/* Added 117968-a1                                                                    */
/* Added 117968-a1                                                                    */
/* Increased character length for deployment date to accommodate notes                */
/**************************************************************************************/


--Clean up temp tables from last invocation
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Deployment_Job_Steps_TEMP]') AND type in (N'U'))
BEGIN
DROP TABLE spc_dba_utilities..Deployment_Job_Steps_TEMP
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Deployment_Job_TEMP]') AND type in (N'U'))
BEGIN
DROP TABLE spc_dba_utilities..Deployment_Job_TEMP
END

--Variables
DECLARE @StagingJobName VARCHAR(MAX)
DECLARE @DeploymentJobName VARCHAR(MAX)
DECLARE @Description VARCHAR(MAX)
DECLARE @EngineerSID VARBINARY(85)

SET @StagingJobName = 'Code Staging - '
SET @DeploymentJobName = 'Code Deployment - '
SET @Description = 'This job has been created as a copy of the Code Staging job with the same name'
SET @EngineerSID = 0xFF977A28934B2A4C822247B758F112B7



/*
--owner_sid obtained by creating an explicit (non-group) login, 
--assign job ownership to that login, 
--view * from sysjobs, 
--find corresponding owner_sid, 
--use that owner_sid to generate the creation stored proc, 
--delete explicit login.
--0x010500000000000515000000E71CD76E810BE368E669446E694C0200 adm-smccord
--0x010500000000000515000000E71CD76E810BE368E669446E2E2C0200 adm-nbrandon
--0x010500000000000515000000E71CD76E810BE368E669446E7D480200 sql_DBA_fnctn
--0x010500000000000515000000E71CD76E810BE368E669446E59410200 AMGDBA

--0x010500000000000515000000E5B45D8433DBFA030F31E6E9C73F0000 117968-a1 (W-AUTH)
--0x010500000000000515000000E5B45D8433DBFA030F31E6E95A0F0000 117962-a1 (W-AUTH)
--0xFF977A28934B2A4C822247B758F112B7 -117968-a1 (S-AUTH)
--0x96A98F38A7230D4DBC5DF0C8385F542D -117962-a1 (S-AUTH)

*/





--Create temp table for new job record
SELECT *
INTO spc_dba_utilities.dbo.Deployment_Job_TEMP
FROM msdb.dbo.sysjobs
WHERE name = @StagingJobName + @StagingJobSubmitter
--Modify temp table record
UPDATE spc_dba_utilities.dbo.Deployment_Job_TEMP
SET name = @DeploymentJobName + @StagingJobSubmitter + ' ' + @DeploymentJobDate
	,job_id = NEWID()
	,owner_sid = @EngineerSID
	,description = @Description
	,date_created = getdate()
	,date_modified = getdate()
	,version_number = 3
--Insert modified record into system table
INSERT INTO msdb.dbo.sysjobs
SELECT *
FROM spc_dba_utilities.dbo.Deployment_Job_TEMP


--Create temp table for new job steps
SELECT a.*
INTO spc_dba_utilities..Deployment_Job_Steps_TEMP
FROM msdb.dbo.sysjobsteps a
INNER JOIN msdb.dbo.sysjobs b
	ON a.job_id = b.job_id
WHERE b.name = @StagingJobName + @StagingJobSubmitter
--Modify temp table records
UPDATE spc_dba_utilities..Deployment_Job_Steps_TEMP
SET job_id = (
		SELECT job_id
		FROM msdb.dbo.sysjobs
		WHERE name = @DeploymentJobName + @StagingJobSubmitter + ' ' + @DeploymentJobDate
		)
	,step_uid = NEWID()
--Insert modified records into system table
INSERT INTO msdb.dbo.sysjobsteps
SELECT *
FROM spc_dba_utilities.dbo.Deployment_Job_Steps_TEMP

--Execute system stored procedure to update the SQL Agent cache
DECLARE @new_job_id uniqueidentifier
SET @new_job_id = (select job_id from msdb.dbo.sysjobs where name = @DeploymentJobName + @StagingJobSubmitter + ' ' + @DeploymentJobDate)
EXEC msdb.dbo.sp_add_jobserver @new_job_id


END

GO
