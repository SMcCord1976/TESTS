USE [spc_dba_utilities]
GO
/****** Object:  View [dbo].[test_view_creation_for_deployment]    Script Date: 8/15/2024 4:33:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[test_view_creation_for_deployment]
AS

SELECT TOP 10* FROM [msdb].[dbo].[sysjobhistory]
GO
