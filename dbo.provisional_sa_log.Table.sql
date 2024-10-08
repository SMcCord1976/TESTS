USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[provisional_sa_log]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[provisional_sa_log](
	[record_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[instance_name] [varchar](50) NULL,
	[user_email] [varchar](50) NULL,
	[rndm_gen_pw] [varchar](50) NULL,
	[pw_gen_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[provisional_sa_log] ADD  CONSTRAINT [DF_provisional_sa_log_pw_gen_date]  DEFAULT (getdate()) FOR [pw_gen_date]
GO
