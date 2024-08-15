USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_windowslogincheck]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_windowslogincheck](
	[LoginName] [sysname] NOT NULL,
	[ADUserName] [nvarchar](1000) NULL,
	[IsDisabled] [bit] NULL
) ON [PRIMARY]
GO
