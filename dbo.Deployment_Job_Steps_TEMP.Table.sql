USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[Deployment_Job_Steps_TEMP]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Deployment_Job_Steps_TEMP](
	[job_id] [uniqueidentifier] NOT NULL,
	[step_id] [int] NOT NULL,
	[step_name] [sysname] NOT NULL,
	[subsystem] [nvarchar](40) NOT NULL,
	[command] [nvarchar](max) NULL,
	[flags] [int] NOT NULL,
	[additional_parameters] [nvarchar](max) NULL,
	[cmdexec_success_code] [int] NOT NULL,
	[on_success_action] [tinyint] NOT NULL,
	[on_success_step_id] [int] NOT NULL,
	[on_fail_action] [tinyint] NOT NULL,
	[on_fail_step_id] [int] NOT NULL,
	[server] [sysname] NULL,
	[database_name] [sysname] NULL,
	[database_user_name] [sysname] NULL,
	[retry_attempts] [int] NOT NULL,
	[retry_interval] [int] NOT NULL,
	[os_run_priority] [int] NOT NULL,
	[output_file_name] [nvarchar](200) NULL,
	[last_run_outcome] [int] NOT NULL,
	[last_run_duration] [int] NOT NULL,
	[last_run_retries] [int] NOT NULL,
	[last_run_date] [int] NOT NULL,
	[last_run_time] [int] NOT NULL,
	[proxy_id] [int] NULL,
	[step_uid] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
