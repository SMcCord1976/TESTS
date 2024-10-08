USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[database_level_role_attestation_TEMP]    Script Date: 8/15/2024 4:33:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[database_level_role_attestation_TEMP](
	[DATABASE_NAME] [nvarchar](128) NULL,
	[DB_USER_NAME] [sysname] NOT NULL,
	[DB_ROLE] [nvarchar](128) NOT NULL,
	[LOGIN_ACCOUNT_TYPE] [nvarchar](60) NULL
) ON [PRIMARY]
GO
