USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[test_table_for_deployment]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[test_table_for_deployment](
	[name] [sysname] NOT NULL,
	[step_name] [sysname] NOT NULL,
	[run_status] [int] NOT NULL,
	[run_date] [int] NOT NULL
) ON [PRIMARY]
GO
