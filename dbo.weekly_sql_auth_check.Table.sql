USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[weekly_sql_auth_check]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[weekly_sql_auth_check](
	[ServerInstanceName] [nvarchar](128) NULL,
	[AccountName] [sysname] NOT NULL,
	[hasaccess] [int] NULL,
	[sysadmin] [int] NULL,
	[securityadmin] [int] NULL,
	[PasswordLastSetTime] [sql_variant] NULL,
	[IsMustChange] [sql_variant] NULL,
	[DaysUntilExpiration] [sql_variant] NULL,
	[IsExpired] [sql_variant] NULL,
	[IsLocked] [sql_variant] NULL,
	[LockoutTime] [sql_variant] NULL,
	[BadPasswordCount] [sql_variant] NULL,
	[BadPasswordTime] [sql_variant] NULL,
	[DefaultLanguage] [sql_variant] NULL,
	[DefaultDatabase] [sql_variant] NULL
) ON [PRIMARY]
GO
