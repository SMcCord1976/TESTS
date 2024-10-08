USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_provisional_sa_access]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dba_sp_provisional_sa_access] @username NVARCHAR(255)
AS

BEGIN 

INSERT INTO [provisional_sa_log]
	([instance_name]
	,[user_email]
	,[rndm_gen_pw])

SELECT 
	@@SERVERNAME
	,@username
	, CAST((SELECT TOP 12 SUBSTRING(tblSource.vssource, tblValue.number + 1, 1) 
        FROM   (SELECT 
       'abcdefhkmnpqrstuvwxyzABCDEFHKMNPQRSTUVWXYZ23456789+=-_~#$%*()' 
       AS 
               vsSource) AS tblSource 
               JOIN master..spt_values AS tblValue 
                 ON tblValue.number < LEN(tblSource.vssource) 
        WHERE  tblValue.type = 'P' 
        ORDER  BY NEWID()
        FOR xml path (''))  
AS VARCHAR(MAX)) AS [rndm_gen_pw];

END
GO
