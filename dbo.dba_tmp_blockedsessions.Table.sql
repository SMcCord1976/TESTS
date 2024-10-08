USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[dba_tmp_blockedsessions]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_tmp_blockedsessions](
	[BLOCKED_session_id] [smallint] NULL,
	[BLOCKED_session_status] [nvarchar](50) NULL,
	[BLOCKING_session_id] [smallint] NULL,
	[wait_type] [nvarchar](128) NULL,
	[wait_resource] [nvarchar](max) NULL,
	[seconds_spent_waiting] [numeric](17, 6) NULL,
	[total_seconds_elapsed] [numeric](17, 6) NULL,
	[BLOCKED_statement_text] [nvarchar](max) NULL,
	[BLOCKED_command_text] [nvarchar](max) NULL,
	[BLOCKED_command_type] [nvarchar](128) NULL,
	[BLOCKED_login_name] [nvarchar](255) NULL,
	[BLOCKED_host_name] [nvarchar](255) NULL,
	[BLOCKED_program_name] [nvarchar](255) NULL,
	[BLOCKED_windows_host_process_id] [int] NULL,
	[last_request_end_time] [datetime] NULL,
	[login_time] [datetime] NULL,
	[open_transaction_count] [int] NULL,
	[cpu_time] [int] NULL,
	[logical_reads] [bigint] NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[InsertedDate] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[dba_tmp_blockedsessions] ADD  DEFAULT (getdate()) FOR [InsertedDate]
GO
