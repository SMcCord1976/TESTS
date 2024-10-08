USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_restorehistory]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_restorehistory](
	[SourceBackupCreatedBy] [nvarchar](max) NULL,
	[SourceBackupFinishDate] [datetime] NULL,
	[SourceBackupMachineName] [nvarchar](max) NULL,
	[SourceSQLServerName] [nvarchar](max) NULL,
	[SourceDBName] [nvarchar](max) NULL,
	[SourceDBCollation] [nvarchar](max) NULL,
	[SourceDBVersion] [int] NULL,
	[SourceRecoveryModel] [nvarchar](60) NULL,
	[SourceDBCompatibilityLevel] [varchar](max) NULL,
	[DestinationDBName] [nvarchar](max) NULL,
	[RestoreType] [varchar](max) NULL,
	[DBRestoreDate] [datetime] NULL,
	[DBRestoredBy] [nvarchar](max) NULL,
	[SourceBackup] [nvarchar](max) NULL,
	[DestinationPhysicalFileName] [nvarchar](max) NULL,
	[SourceSingleUserYesNo] [varchar](5) NULL,
	[SourceDamagedYesNo] [varchar](5) NULL,
	[SourceReadOnlyYesNo] [varchar](5) NULL,
	[SourceCopyOnlyYesNo] [varchar](5) NULL,
	[SourceIncompleteMetaDataYesNo] [varchar](5) NULL,
	[InsertedDate] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[dba_tmp_restorehistory] ADD  DEFAULT (getdate()) FOR [InsertedDate]
GO
