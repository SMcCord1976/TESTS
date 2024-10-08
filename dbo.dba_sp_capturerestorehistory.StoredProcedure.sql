USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_capturerestorehistory]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE   PROCEDURE [dbo].[dba_sp_capturerestorehistory]

AS

BEGIN



IF NOT EXISTS (select name from sysobjects where name = 'dba_tmp_restorehistory')
CREATE TABLE [dbo].[dba_tmp_restorehistory](
	[SourceBackupCreatedBy] [nvarchar](MAX) NULL,
	[SourceBackupFinishDate] [datetime] NULL,
	[SourceBackupMachineName] [nvarchar](MAX) NULL,
	[SourceSQLServerName] [nvarchar](MAX) NULL,
	[SourceDBName] [nvarchar](MAX) NULL,
	[SourceDBCollation] [nvarchar](MAX) NULL,
	[SourceDBVersion] [int] NULL,
	[SourceRecoveryModel] [nvarchar](60) NULL,
	[SourceDBCompatibilityLevel] [varchar](MAX) NULL,
	[DestinationDBName] [nvarchar](MAX) NULL,
	[RestoreType] [varchar](MAX) NULL,
	[DBRestoreDate] [datetime] NULL,
	[DBRestoredBy] [nvarchar](MAX) NULL,
	[SourceBackup] [nvarchar](MAX) NULL,
	[DestinationPhysicalFileName] [nvarchar](MAX) NULL,
	[SourceSingleUserYesNo] [varchar](5) NULL,
	[SourceDamagedYesNo] [varchar](5) NULL,
	[SourceReadOnlyYesNo] [varchar](5) NULL,
	[SourceCopyOnlyYesNo] [varchar](5) NULL,
	[SourceIncompleteMetaDataYesNo] [varchar](5) NULL,
	[InsertedDate] [datetime] NOT NULL
) ON [PRIMARY]

--ALTER TABLE [dbo].[dba_tmp_restorehistory] ADD  DEFAULT (getdate()) FOR [InsertedDate]

--select * from sys.default_constraints



IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE [name] = 'DF__dba_tmp_r__Inser__5EBF139D')
ALTER TABLE [dbo].[dba_tmp_restorehistory] ADD  DEFAULT (getdate()) FOR [InsertedDate]
ELSE
    print 'Constraint already exists.  Create ignored.';


INSERT INTO spc_dba_utilities.dbo.dba_tmp_restorehistory
           ([SourceBackupCreatedBy]
           ,[SourceBackupFinishDate]
           ,[SourceBackupMachineName]
           ,[SourceSQLServerName]
           ,[SourceDBName]
           ,[SourceDBCollation]
           ,[SourceDBVersion]
           ,[SourceRecoveryModel]
           ,[SourceDBCompatibilityLevel]
           ,[DestinationDBName]
           ,[RestoreType]
           ,[DBRestoreDate]
           ,[DBRestoredBy]
           ,[SourceBackup]
           ,[DestinationPhysicalFileName]
           ,[SourceSingleUserYesNo]
           ,[SourceDamagedYesNo]
           ,[SourceReadOnlyYesNo]
           ,[SourceCopyOnlyYesNo]
           ,[SourceIncompleteMetaDataYesNo])
SELECT d.user_name AS [SourceBackupCreatedBy]
       ,d.backup_finish_date AS [SourceBackupFinishDate]
       ,d.machine_name AS [SourceBackupMachineName]
       ,d.server_name AS [SourceSQLServerName]
       ,d.database_name AS [SourceDBName]
       ,d.collation_name AS [SourceDBCollation]
       ,d.database_version AS [SourceDBVersion]
       ,d.recovery_model AS [SourceRecoveryModel]
       ,CASE 
              WHEN d.compatibility_level = '90'
                     THEN 'SQL Server 2005'
              WHEN d.compatibility_level = '100'
                     THEN 'SQL Server 2008'
              WHEN d.compatibility_level = '110'
                     THEN 'SQL Server 2012'
              WHEN d.compatibility_level = '120'
                     THEN 'SQL Server 2014'
              WHEN d.compatibility_level = '130'
                     THEN 'SQL Server 2016'
              WHEN d.compatibility_level = '140'
                     THEN 'SQL Server 2017'
              WHEN d.compatibility_level = '150'
                     THEN 'SQL Server 2019'
              WHEN d.compatibility_level = '160'
                     THEN 'SQL Server 2022'
              ELSE CAST(d.compatibility_level AS NVARCHAR(MAX))
              END AS [SourceDBCompatibilityLevel]
       ,a.destination_database_name AS [DestinationDBName]
       ,CASE 
              WHEN a.restore_type = 'D'
                     THEN 'DATABASE RESTORE'
              WHEN a.restore_type = 'F'
                     THEN 'FILE RESTORE'
              WHEN a.restore_type = 'I'
                     THEN 'DIFFERENTIAL RESTORE'
              WHEN a.restore_type = 'L'
                     THEN 'TRANSACTION LOG RESTORE'
              ELSE a.restore_type
              END AS [RestoreType]
       ,a.restore_date AS [DBRestoreDate]
       ,a.user_name AS [DBRestoredBy] --Can enable auditing to determine who logged in as sa account 
       ,b.physical_device_name AS [SourceBackup]
       ,c.destination_phys_name AS [DestinationPhysicalFileName]
       ,CASE 
              WHEN d.is_single_user = 1
                     THEN 'YES'
              WHEN d.is_single_user = 0
                     THEN 'NO'
              ELSE CAST(d.is_single_user AS NVARCHAR(5))
              END AS [SourceSingleUserYesNo]
       ,CASE 
              WHEN d.is_damaged = 1
                     THEN 'YES'
              WHEN d.is_damaged = 0
                     THEN 'NO'
              ELSE CAST(d.is_damaged AS NVARCHAR(5))
              END AS [SourceDamagedYesNo]
       ,CASE 
              WHEN d.is_readonly = 1
                     THEN 'YES'
              WHEN d.is_readonly = 0
                     THEN 'NO'
              ELSE CAST(d.is_readonly AS NVARCHAR(5))
              END AS [SourceReadOnlyYesNo]
       ,CASE 
              WHEN d.is_copy_only = 1
                     THEN 'YES'
              WHEN d.is_copy_only = 0
                     THEN 'NO'
              ELSE CAST(d.is_copy_only AS NVARCHAR(5))
              END AS [SourceCopyOnlyYesNo]
       ,CASE 
              WHEN d.has_incomplete_metadata = 1
                     THEN 'YES'
              WHEN d.has_incomplete_metadata = 0
                     THEN 'NO'
              ELSE CAST(d.has_incomplete_metadata AS NVARCHAR(5))
              END AS [SourceIncompleteMetaDataYesNo]
FROM [msdb].[dbo].[restorehistory] a
JOIN [msdb].[dbo].[backupset] d
       ON a.backup_set_id = d.backup_set_id
JOIN [msdb].[dbo].[restorefile] c
       ON a.restore_history_id = c.restore_history_id
JOIN [msdb].[dbo].[backupmediafamily] b
       ON b.media_set_id = d.media_set_id
ORDER BY a.restore_date DESC

END
GO
