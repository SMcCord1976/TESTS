USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_orphanedusers]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_orphanedusers](
	[-- REMAP STATEMENT --] [nvarchar](max) NOT NULL,
	[-- SERVER NAME --] [nvarchar](128) NULL,
	[-- INSTANCE NAME --] [nvarchar](128) NULL,
	[-- DATABASE NAME --] [nvarchar](128) NULL,
	[-- TIME STAMP --] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
