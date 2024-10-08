USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_blockinfo]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_blockinfo](
	[lock_type] [nvarchar](120) NULL,
	[database_id] [nvarchar](150) NULL,
	[blk_object] [bigint] NULL,
	[lock_req] [nvarchar](120) NULL,
	[wait_sid] [bigint] NULL,
	[wait_time] [sysname] NOT NULL,
	[wait_type] [nvarchar](60) NULL,
	[wait_batch] [varchar](max) NULL,
	[wait_stmt] [varchar](max) NULL,
	[block_stmt] [varchar](max) NULL,
	[blocker_sid] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
