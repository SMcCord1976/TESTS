USE [spc_dba_utilities]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_SIDToString]    Script Date: 8/15/2024 4:33:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- function to translate binary format SID into Active Directory string-based-format
CREATE FUNCTION [dbo].[fn_SIDToString]
(
    @BinSID AS varbinary(100)
)
RETURNS varchar(100)
AS 
BEGIN
    IF LEN(@BinSID) % 4 <> 0 RETURN(NULL);
 
    DECLARE @StringSID varchar(100);
    DECLARE @i AS int;
    DECLARE @j AS int;
 
    SET @StringSID = 'S-'
        + CONVERT(varchar(100), CONVERT(int, CONVERT(varbinary(100), SUBSTRING(@BinSID, 1, 1))));
    SET @StringSID = @StringSID + '-'
        + CONVERT(varchar(100), CONVERT(int, CONVERT(varbinary(100), SUBSTRING(@BinSID, 3, 6))));
 
    SET @j = 9;
    SET @i = LEN(@BinSID);
 
    WHILE @j < @i
    BEGIN
        DECLARE @val binary(4);
        SET @val = SUBSTRING(@BinSID, @j, 4);
        SET @StringSID = @StringSID + '-'
        + CONVERT(varchar(100), CONVERT(bigint, CONVERT(varbinary(100), REVERSE(CONVERT(varbinary(100), @val)))));
        SET @j = @j + 4;
    END
    RETURN @StringSID;
END
GO
