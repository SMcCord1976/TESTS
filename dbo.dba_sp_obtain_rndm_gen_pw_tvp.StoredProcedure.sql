USE [spc_dba_utilities]
GO
/****** Object:  StoredProcedure [dbo].[dba_sp_obtain_rndm_gen_pw_tvp]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROCEDURE [dbo].[dba_sp_obtain_rndm_gen_pw_tvp]
 AS 
 BEGIN

 DECLARE @pwd_variable AS provisional_sa_rndm_pw

 INSERT INTO @pwd_variable
 SELECT a.[rndm_gen_pw] FROM spc_dba_utilities.dbo.[provisional_sa_log] a 
 INNER JOIN (SELECT MAX([record_id]) AS [max_record_id] 
 FROM spc_dba_utilities.dbo.[provisional_sa_log]) b 
 ON a.[record_id] = b.[max_record_id]

 END
GO
