USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_weekly_dashboard_report_test]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_weekly_dashboard_report_test](
	[ServerInstanceName] [nvarchar](128) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CheckID] [int] NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[Priority] [tinyint] NULL,
	[FindingsGroup] [varchar](50) NULL,
	[Finding] [varchar](200) NULL,
	[URL] [varchar](200) NULL,
	[Details] [nvarchar](4000) NULL,
	[QueryPlan] [xml] NULL,
	[QueryPlanFiltered] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
