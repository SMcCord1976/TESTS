USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_running_job_check]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dba_sp_running_job_check]
AS

BEGIN

IF EXISTS (
		SELECT *
		FROM tempdb.dbo.sysobjects
		WHERE id = OBJECT_ID(N'[tempdb].[dbo].[Temp1]')
		)
	DROP TABLE [tempdb].[dbo].[Temp1]


CREATE TABLE [tempdb].[dbo].[Temp1] (
	job_id UNIQUEIDENTIFIER NOT NULL
	,last_run_date NVARCHAR(20) NOT NULL
	,last_run_time NVARCHAR(20) NOT NULL
	,next_run_date NVARCHAR(20) NOT NULL
	,next_run_time NVARCHAR(20) NOT NULL
	,next_run_schedule_id INT NOT NULL
	,requested_to_run INT NOT NULL
	,request_source INT NOT NULL
	,request_source_id SYSNAME COLLATE database_default NULL
	,running INT NOT NULL
	,current_step INT NOT NULL
	,current_retry_attempt INT NOT NULL
	,job_state INT NOT NULL
	)

DECLARE @job_owner SYSNAME
DECLARE @is_sysadmin INT

SET @is_sysadmin = isnull(is_srvrolemember('sysadmin'), 0)
SET @job_owner = suser_sname()

INSERT INTO [tempdb].[dbo].[Temp1]
--EXECUTE sys.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin
	,@job_owner

UPDATE [tempdb].[dbo].[Temp1]
SET last_run_time = right('000000' + last_run_time, 6)
	,next_run_time = right('000000' + next_run_time, 6);

-----
SELECT j.NAME AS JobName
	,j.enabled AS Enabled
	,CASE x.running
		WHEN 1
			THEN 'Running'
		ELSE CASE h.run_status
				WHEN 2
					THEN 'Inactive'
				WHEN 4
					THEN 'Inactive'
				ELSE 'Completed'
				END
		END AS CurrentStatus
	,coalesce(x.current_step, 0) AS CurrentStepNbr
	,CASE 
		WHEN x.last_run_date > 0
			THEN convert(DATETIME, substring(x.last_run_date, 1, 4) + '-' + substring(x.last_run_date, 5, 2) + '-' + substring(x.last_run_date, 7, 2) + ' ' + substring(x.last_run_time, 1, 2) + ':' + substring(x.last_run_time, 3, 2) + ':' + substring(x.last_run_time, 5, 2) + '.000', 121)
		ELSE NULL
		END AS LastRunTime
	,CASE h.run_status
		WHEN 0
			THEN 'Fail'
		WHEN 1
			THEN 'Success'
		WHEN 2
			THEN 'Retry'
		WHEN 3
			THEN 'Cancel'
		WHEN 4
			THEN 'In progress'
		END AS LastRunOutcome
	,CASE 
		WHEN h.run_duration > 0
			THEN (h.run_duration / 1000000) * (3600 * 24) + (h.run_duration / 10000 % 100) * 3600 + (h.run_duration / 100 % 100) * 60 + (h.run_duration % 100)
		ELSE NULL
		END AS LastRunDuration
FROM [tempdb].[dbo].[Temp1] x
LEFT JOIN msdb.dbo.sysjobs j
	ON x.job_id = j.job_id
LEFT JOIN msdb.dbo.syscategories c
	ON j.category_id = c.category_id
LEFT JOIN msdb.dbo.sysjobhistory h
	ON x.job_id = h.job_id
		AND x.last_run_date = h.run_date
		AND x.last_run_time = h.run_time
		AND h.step_id = 0
WHERE x.running = 1
AND j.NAME not like 'DBA - Jobs Currently Running%'

END


GO
