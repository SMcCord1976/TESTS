USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[DB_MAIL_ATTRIBUTES_TEMP]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DB_MAIL_ATTRIBUTES_TEMP](
	[SERVER_NAME] [varchar](max) NULL,
	[CAPTURE_DATE] [datetime] NULL,
	[profile_id] [int] NULL,
	[profile_name] [varchar](max) NULL,
	[account_id] [int] NULL,
	[account_name] [varchar](max) NULL,
	[account_description] [varchar](max) NULL,
	[from_email_address] [varchar](max) NULL,
	[account_display_name] [varchar](max) NULL,
	[replyto_address] [varchar](max) NULL,
	[servertype] [varchar](max) NULL,
	[servername] [varchar](max) NULL,
	[port] [varchar](max) NULL,
	[account_username] [varchar](max) NULL,
	[use_default_credentials] [int] NULL,
	[enable_ssl] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
