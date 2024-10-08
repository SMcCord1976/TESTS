USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_windows_group_check]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_windows_group_check](
	[GroupName] [varchar](8) NOT NULL,
	[sAMAccountName] [nvarchar](4000) NULL,
	[displayName] [nvarchar](4000) NULL,
	[AdsPath] [nvarchar](256) NULL,
	[LastLogon] [datetime2](7) NULL
) ON [PRIMARY]
GO
