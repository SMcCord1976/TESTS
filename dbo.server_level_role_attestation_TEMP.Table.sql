USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[server_level_role_attestation_TEMP]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[server_level_role_attestation_TEMP](
	[SERVER_LOGIN_NAME] [sysname] NOT NULL,
	[LOGIN_ACCOUNT_TYPE] [varchar](23) NULL,
	[IS_WINDOWS_GROUP] [varchar](42) NULL,
	[IS_WINDOWS_USER] [varchar](26) NULL,
	[IS_sysadmin] [varchar](23) NULL,
	[IS_serveradmin] [varchar](26) NULL,
	[IS_processadmin] [varchar](27) NULL,
	[IS_dbcreator] [varchar](24) NULL,
	[IS_setupadmin] [varchar](25) NULL
) ON [PRIMARY]
GO
