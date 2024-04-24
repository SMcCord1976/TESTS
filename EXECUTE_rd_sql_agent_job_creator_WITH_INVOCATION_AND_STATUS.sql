EXEC [amg_dba_utilities].[dbo].[rd_sql_agent_job_creator_adm_smccord] 'AMG-HQ\smccord','20190416'
GO

SELECT *
FROM msdb.dbo.sysjobs
WHERE name LIKE '%20190416%'

SELECT a.name
, b.step_id
, b.step_name
FROM msdb.dbo.sysjobs a
	JOIN msdb.dbo.sysjobsteps b
		ON a.job_id = b.job_id
WHERE name LIKE '%20190416%'
ORDER BY name, step_id
go


EXEC [msdb].[dbo].[sp_start_job] 'Code Deployment - AMG-HQ\smccord 20190416'

SELECT b.name
	,a.step_name
	,CASE a.run_status
		WHEN 1 THEN 'The step succeeded'
		WHEN 0 THEN 'The step failed'
		ELSE 'Unknown status'
	END AS 'run_status'
	,a.run_date
FROM msdb.dbo.sysjobhistory a
INNER JOIN msdb.dbo.sysjobs b
	ON a.job_id = b.job_id
WHERE b.name LIKE '%20190416%'
GO

