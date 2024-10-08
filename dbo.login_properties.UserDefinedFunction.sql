USE [spc_dba_utilities]
GO
/****** Object:  UserDefinedFunction [dbo].[login_properties]    Script Date: 8/15/2024 4:33:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[login_properties](@login_name NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN SELECT
LOGINPROPERTY(@login_name,'BadPasswordCount') AS [BadPasswordCount],
LOGINPROPERTY(@login_name,'BadPasswordTime') AS [BadPasswordTime],
LOGINPROPERTY(@login_name,'DaysUntilExpiration') AS [DaysUntilExpiration],
LOGINPROPERTY(@login_name,'DefaultDatabase') AS [DefaultDatabase],
LOGINPROPERTY(@login_name,'DefaultLanguage') AS [DefaultLanguage],
LOGINPROPERTY(@login_name,'HistoryLength') AS [HistoryLength],
LOGINPROPERTY(@login_name,'IsExpired') AS [IsExpired],
LOGINPROPERTY(@login_name,'IsLocked') AS [IsLocked],
LOGINPROPERTY(@login_name,'IsMustChange') AS [IsMustChange],
LOGINPROPERTY(@login_name,'LockoutTime') AS [LockoutTime],
LOGINPROPERTY(@login_name,'PasswordHash') AS [PasswordHash],
LOGINPROPERTY(@login_name,'PasswordLastSetTime') AS [PasswordLastSetTime],
LOGINPROPERTY(@login_name,'PasswordHashAlgorithm') AS [PasswordHashAlgorithm];
GO
