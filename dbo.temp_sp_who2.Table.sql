USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[temp_sp_who2]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_sp_who2](
	[SPID] [int] NULL,
	[Status] [varchar](1000) NULL,
	[LOGIN] [sysname] NULL,
	[HostName] [sysname] NULL,
	[BlkBy] [sysname] NULL,
	[DBName] [sysname] NULL,
	[Command] [varchar](1000) NULL,
	[CPUTime] [int] NULL,
	[DiskIO] [int] NULL,
	[LastBatch] [varchar](1000) NULL,
	[ProgramName] [varchar](1000) NULL,
	[SPID2] [int] NULL,
	[RequestID] [int] NULL,
	[InsertedDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[temp_sp_who2] ADD  DEFAULT (getdate()) FOR [InsertedDate]
GO
