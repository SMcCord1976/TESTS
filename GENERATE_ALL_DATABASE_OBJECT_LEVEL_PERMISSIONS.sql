----------------------------------------------
--Login Pre-requisites
----------------------------------------------

/** THIS PROCEDURE RELIES UPON THE EXISTENCE OF THE sp_hexadecimal STORED PROCEDURE **/



/****** SUPPLY LOGIN INFORMATION BELOW ******/

set concat_null_yields_null off
USE master
go
SET NOCOUNT ON
DECLARE @login_name varchar(100)
SET @login_name = 'LOGIN' --<< SUPPLY LOGIN INFORMATION HERE
 
-----------------------------------------------------------------
 
IF lower(@login_name) IN ('sa','public')
BEGIN
      RAISERROR (15405,11,1,@login_name)
      RETURN
END
 
 
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @login_name AND type IN ('G','U','S'))
BEGIN
      PRINT 'Please input valid login name'
      RETURN
END
 
 
DECLARE @login_sid varbinary(85)
SELECT @login_sid = sid FROM sys.server_principals WHERE name = @login_name
 
DECLARE @maxid int
 
IF OBJECT_ID('tempdb..#db_users') is not null
BEGIN
      DROP TABLE #db_users
END
 
SELECT id = identity(int,1,1), sql_cmd = 'SELECT '''+name+''', * FROM ['+name+'].sys.database_principals' INTO #db_users FROM sys.databases
WHERE state_desc <> 'OFFLINE'
 
SELECT @maxid = @@ROWCOUNT
 
 
----------------------------------------------
--Create Server Role Temp table
----------------------------------------------
 
IF OBJECT_ID('tempdb..#srvrole') IS NOT NULL
BEGIN
      DROP TABLE #srvrole
END
 
CREATE TABLE #srvrole(ServerRole sysname, MemberName sysname, MemberSID varbinary(85)) 
INSERT INTO [#srvrole] EXEC sp_helpsrvrolemember
 
DECLARE @login_srvrole varchar(1000)
SET @login_srvrole = ''
IF EXISTS (select * from [#srvrole] where ServerRole = 'sysadmin' AND MemberName = @login_name)
BEGIN
     
      PRINT '--Login ['+@login_name+'] is part of sysadmin server role, hence possesses full privileges for SQL instance: '+@@servername
      PRINT 'GO'
      SELECT @login_srvrole = @login_srvrole + 'EXEC sp_addsrvrolemember '''+MemberName+''','''+ServerRole+''''+CHAR(10) FROM #srvrole
      WHERE [MemberName] = @login_name
      PRINT @login_srvrole
      RETURN
      RETURN
END
 
---------------------------------------------------
--Find out list of db that the login has access to
---------------------------------------------------
 
PRINT ''
PRINT '----------------------------------------------'
PRINT '--Create database user for login '
PRINT '----------------------------------------------'
 
IF OBJECT_ID('tempdb..#alldb_users') is not null
BEGIN
      DROP TABLE #alldb_users
END
 
CREATE TABLE #alldb_users(
      [dbname] [sysname] NOT NULL,
      [name] [sysname] NOT NULL,
      [principal_id] [int] NOT NULL,
      [type] [char](1) NOT NULL,
      [type_desc] [nvarchar](60) NULL,
      [default_schema_name] [sysname] NULL,
      [create_date] [datetime] NOT NULL,
      [modify_date] [datetime] NOT NULL,
      [owning_principal_id] [int] NULL,
      [sid] [varbinary](85) NULL,
      [is_fixed_role] [bit] NOT NULL
)
 
DECLARE @id int, @sqlcmd varchar(500)
SET @id = 1
WHILE @id <=@maxid
BEGIN
      SELECT @sqlcmd = sql_cmd FROM #db_users WHERE id = @id
      INSERT INTO #alldb_users EXEC (@sqlcmd)
      SET @id = @id + 1
END
 
 
DELETE FROM #alldb_users WHERE sid is null
 
DELETE FROM #alldb_users WHERE sid <> @login_sid
 
IF NOT EXISTS (SELECT * FROM #alldb_users )
BEGIN
      PRINT '--Login ['+@login_name+'] doesnt have access to any database'
END
 
DECLARE @name sysname, @dbname sysname, @schema sysname, @dbuser_cmd varchar(200)
DECLARE dbuser_cursor CURSOR FOR
SELECT dbname, name, default_schema_name
FROM #alldb_users
 
OPEN dbuser_cursor
FETCH NEXT FROM dbuser_cursor INTO @dbname, @name, @schema
WHILE @@FETCH_STATUS = 0
BEGIN
 
IF @schema IS NOT NULL
BEGIN    
SELECT @dbuser_cmd = 'USE ['+dbname+']
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '''+name+''')
BEGIN
      CREATE USER ['+@name+'] FOR LOGIN ['+@login_name+']'+isnull(' WITH DEFAULT_SCHEMA=['+default_schema_name+']','')+'
END
 
' FROM #alldb_users WHERE name = @name and dbname = @dbname
END
ELSE
BEGIN
SELECT @dbuser_cmd = 'USE ['+dbname+']
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '''+name+''')
BEGIN
      CREATE USER ['+@name+'] FOR LOGIN ['+@login_name+']
END
 
' FROM #alldb_users WHERE name = @name and dbname = @dbname
END
 
      print @dbuser_cmd
    FETCH NEXT FROM dbuser_cursor INTO @dbname, @name, @schema
    END
 
CLOSE dbuser_cursor
DEALLOCATE dbuser_cursor
 
 
----------------------------------------------
--granting database role to login
----------------------------------------------
IF OBJECT_ID('tempdb..#dbrole') is not null
BEGIN
      DROP TABLE #dbrole
END
 
create table #dbrole (id int identity(1,1), dbname varchar(100), dbrole varchar (100), dbrole_member varchar(100), sid varbinary(85), default_schema_name varchar(100), login_name varchar(100), db_principal_id int)
DECLARE @dbrole_sqlcmd varchar(max)
DECLARE dbrole_cursor CURSOR FAST_FORWARD FOR
SELECT
'SELECT '''+dbname+''', c.name, b.name, b.sid, b.default_schema_name, d.name, b.principal_id as login_name
from ['+dbname+'].sys.database_role_members a
inner join ['+dbname+'].sys.database_principals b on a.member_principal_id = b.principal_id
inner join ['+dbname+'].sys.database_principals c on a.role_principal_id = c.principal_id
left join sys.server_principals d on b.sid = d.sid
where d.name= '''+@login_name+''''
from #alldb_users
 
OPEN dbrole_cursor
FETCH NEXT FROM dbrole_cursor INTO @dbrole_sqlcmd
WHILE @@FETCH_STATUS = 0
BEGIN
   
    INSERT INTO #dbrole (dbname, dbrole, dbrole_member, sid, default_schema_name, login_name, db_principal_id) exec(@dbrole_sqlcmd)
    FETCH NEXT FROM dbrole_cursor INTO @dbrole_sqlcmd
    END
 
CLOSE dbrole_cursor
DEALLOCATE dbrole_cursor
 
DELETE FROM #dbrole WHERE sid <> @login_sid
 
 
IF EXISTS (SELECT * FROM #dbrole where dbrole = 'db_owner')
BEGIN
      PRINT '----------------------------------------------'
      PRINT'--Login is db_owner of below databases'
      PRINT'----------------------------------------------'
 
END
 
DECLARE @dbname_dbowner varchar(100), @dbrole_member varchar(100)
DECLARE dbowner_cursor CURSOR FAST_FORWARD FOR
SELECT dbname, dbrole_member from #dbrole where dbrole = 'db_owner'
 
OPEN dbowner_cursor
FETCH NEXT FROM dbowner_cursor INTO @dbname_dbowner, @dbrole_member
WHILE @@FETCH_STATUS = 0
BEGIN
 
      PRINT 'USE ['+@dbname_dbowner+']
EXEC sp_addrolemember ''db_owner'','''+@dbrole_member +'''
GO'
    FETCH NEXT FROM dbowner_cursor INTO @dbname_dbowner, @dbrole_member
    END
 
CLOSE dbowner_cursor
DEALLOCATE dbowner_cursor
 
--------------------------------------------------------------------------------------------------------
--Find out what database the login has permission to access (avoid restricted and single user database)
--------------------------------------------------------------------------------------------------------
 
 
DELETE From #srvrole where MemberName <> @login_name
 
IF OBJECT_ID('tempdb..#alldb_users_access') IS NOT NULL
BEGIN
      DROP TABLE #alldb_users_access
END
 
SELECT a.*, collation_name INTO #alldb_users_access FROM #alldb_users a inner join sys.databases b ON a.dbname = b.name
WHERE user_access = 0
OR
(user_access = 2 and exists (SELECT * FROM #srvrole WHERE ServerRole in ('dbcreator','sysadmin')))
OR
(user_access = 2 and a.dbname in (SELECT dbname FROM #dbrole WHERE dbrole = 'db_owner' AND login_name = @login_name))
 
 
--SELECT * FROM #alldb_users_access
 
--------------------------------------------------------------------------------------------------------
--Remove database that login doesnt have permission to connect
--------------------------------------------------------------------------------------------------------
 
IF OBJECT_ID('tempdb..#dbconnect') is not null
BEGIN
      DROP TABLE #dbconnect
END
 
CREATE TABLE #dbconnect ( dbname varchar(100), connect_status bit)
 
DECLARE @dbconnect_sqlcmd varchar(1000)
SET @dbconnect_sqlcmd  = ''
DECLARE dbbconnect_cursor CURSOR FAST_FORWARD FOR
SELECT 'select distinct '''+dbname+''', 1 from ['+dbname+'].sys.database_permissions a
inner join ['+dbname+'].sys.database_principals b on a.grantee_principal_id = b.principal_id
inner join ['+dbname+'].sys.server_principals c on b.sid = c.sid
where c.name = '''+@login_name+''''
from #alldb_users_access
 
OPEN dbbconnect_cursor
FETCH NEXT FROM dbbconnect_cursor INTO @dbconnect_sqlcmd
WHILE @@FETCH_STATUS = 0
BEGIN
 
      INSERT INTO #dbconnect exec( @dbconnect_sqlcmd)
    FETCH NEXT FROM dbbconnect_cursor INTO @dbconnect_sqlcmd
    END
 
CLOSE dbbconnect_cursor
DEALLOCATE dbbconnect_cursor
 
insert into #dbconnect
select a.dbname, 0 from #alldb_users_access a left join #dbconnect b on a.dbname = b.dbname
where b.dbname is null
 
delete from #alldb_users_access where dbname not in (select dbname from #dbconnect where connect_status= 1 )
delete from #alldb_users_access where dbname in (select dbname from #dbrole where dbrole = 'db_owner')
 
 
---------------------------------------------------------------------------------------
--                                  Grant object level permission
----------------------------------------------------------------------------------------
 
--select USER_NAME(), SUSER_NAME()
 
----------------------------------------------
--database object permission to login
----------------------------------------------
PRINT ''
PRINT '--------------------------------------------------------------'
PRINT '--Grant/Revoking/Denying database object permission to login'
PRINT '---------------------------------------------------------------'
--SELECT * FROM #securable_class WHEREsqlcmd like '%OBJECT%'
--EXECUTE AS Login = 'BrennanJJ'
--SELECT 'AuDB2',* FROM [AuDB2].sys.fn_my_permissions ('AccountHandles', 'OBJECT');
--Revert
 
 
DECLARE @sql_objpermission varchar(8000)
SET @sql_objpermission  = ''
 
 
IF OBJECT_ID('tempdb..#objpermission') IS NOT NULL
BEGIN
      DROP TABLE #objpermission
END
 
CREATE TABLE #objpermission(
      [dbname] [sysname] NOT NULL,
      [obj_name] [nvarchar](128) NULL,
      --[user_name] [nvarchar](128) NULL,
      [class] [tinyint] NOT NULL,
      [class_desc] [nvarchar](60) NULL,
      [major_id] [int] NOT NULL,
      [minor_id] [int] NOT NULL,
      [grantee_principal_id] [int] NOT NULL,
      [grantor_principal_id] [int] NOT NULL,
      [type] [char](4) NOT NULL,
      [permission_name] [nvarchar](128) NULL,
      [state] [char](1) NOT NULL,
      [state_desc] [nvarchar](60) NULL,
      [dbuser] [nvarchar](128) NULL
)
 
DECLARE objlevel_cursor CURSOR FOR
SELECT distinct --@sql_objpermission  = @sql_objpermission +
'SELECT '''+dbname+''' as db_name, ''OBJECT'' COLLATE '+collation_name+' +'' :: [''+d.name+''].[''+b.name+'']'' as obj_name ,a.*, c.name COLLATE '+collation_name+' as dbuser
FROM ['+dbname+'].sys.database_permissions a
inner join ['+dbname+'].sys.sysobjects b on a.major_id = b.id
left join ['+dbname+'].sys.database_principals c on a.grantee_principal_id = c.principal_id
left join ['+dbname+'].sys.sysusers d on b.uid = d.uid
where grantee_principal_id = '+convert(varchar(10),principal_id) + ' AND major_id <> 0 AND minor_id = 0 and class_desc <> ''DATABASE''
 
' from #alldb_users_access a
 
 
--select * from #alldb_users_access
 
 
 
OPEN objlevel_cursor
FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
WHILE @@FETCH_STATUS = 0
BEGIN
   
    --PRINT @sql_objpermission
    --EXEC @sql_objpermission
    INSERT INTO #objpermission EXEC (@sql_objpermission)
    FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
    END
 
CLOSE objlevel_cursor
DEALLOCATE objlevel_cursor
 
--------------------------------------------------------
--New securable types
------------------------------------------------------
 
if OBJECT_ID('tempdb..#securable') IS NOT NULL
BEGIN
      DROP TABLE #securable
END
 
 
CREATE TABLE #securable (Category varchar(50), Securable_Type varchar(50), column_name varchar(50), permission_class varchar(50))
 
--INSERT INTO #securable SELECT 'sysobjects','OBJECT','id'
INSERT INTO #securable SELECT 'assemblies','ASSEMBLY','assembly_id','ASSEMBLY'
INSERT INTO #securable SELECT 'asymmetric_keys','ASYMMETRIC KEY','asymmetric_key_id','ASYMMETRIC_KEY'
INSERT INTO #securable SELECT 'certificates','CERTIFICATE','certificate_id','CERTIFICATE'
INSERT INTO #securable SELECT 'service_contracts','CONTRACT','service_contract_id','SERVICE_CONTRACT'
INSERT INTO #securable SELECT 'fulltext_catalogs','FULLTEXT CATALOG','fulltext_catalog_id','FULLTEXT_CATALOG'
IF @@version like '%SQL Server 2008%'
BEGIN
      INSERT INTO #securable SELECT 'fulltext_stoplists','FULLTEXT STOPLIST','stoplist_id','FULLTEXT_CATALOG'
END
INSERT INTO #securable SELECT 'service_message_types','MESSAGE TYPE','message_type_id','MESSAGE_TYPE'
INSERT INTO #securable SELECT 'remote_service_bindings','REMOTE SERVICE BINDING','remote_service_binding_id','REMOTE_SERVICE_BINDING'
INSERT INTO #securable SELECT 'routes','ROUTE','route_id','ROUTE'
INSERT INTO #securable SELECT 'schemas','SCHEMA','schema_id','SCHEMA'
INSERT INTO #securable SELECT 'services','SERVICE','service_id','SERVICE'
INSERT INTO #securable SELECT 'types','TYPE','user_type_id','TYPE'
INSERT INTO #securable SELECT 'xml_schema_collections','XML SCHEMA COLLECTION','xml_collection_id','XML_SCHEMA_COLLECTION'
 
 
 
DECLARE @category varchar(100), @securable_type varchar(50), @col_name varchar(50), @permission_class varchar(50), @sql_securable varchar(max)--,  @sql_objpermission2 varchar(max)
DECLARE securable_type_cursor CURSOR FOR
SELECT * FROM #securable
 
OPEN securable_type_cursor
FETCH NEXT FROM securable_type_cursor INTO @category, @securable_type, @col_name, @permission_class
WHILE @@FETCH_STATUS = 0
BEGIN
   
            DECLARE objlevel_cursor CURSOR FOR
            SELECT distinct --@sql_objpermission  = @sql_objpermission +
            'SELECT '''+dbname+''' as db_name, '''+@securable_type +''' COLLATE '+collation_name+' +'' :: [''+b1.name+'']'' as obj_name,a.*, c.name as dbuser FROM ['+dbname+'].sys.database_permissions a
            inner join ['+dbname+'].sys.'+@category+' b1 on a.major_id = b1.'+@col_name+'
            left join ['+dbname+'].sys.database_principals c on a.grantee_principal_id = c.principal_id
            where grantee_principal_id = '+convert(varchar(10),principal_id) + ' AND major_id <> 0 AND minor_id = 0 and a.class_desc = '''+@permission_class+'''
 
            ' from #alldb_users_access a
           
            OPEN objlevel_cursor
            FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
            WHILE @@FETCH_STATUS = 0
            BEGIN
               
                  --PRINT @sql_objpermission
                  --EXEC(@sql_objpermission)
                  INSERT INTO #objpermission EXEC (@sql_objpermission)
                  FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
                  END
 
            CLOSE objlevel_cursor
            DEALLOCATE objlevel_cursor
 
    FETCH NEXT FROM securable_type_cursor INTO @category, @securable_type, @col_name, @permission_class
    END
 
CLOSE securable_type_cursor
DEALLOCATE securable_type_cursor
 
 
---------------------------------------------------------
--Database Principal Securable Handling
---------------------------------------------------------
 
 
DELETE FROM #securable
 
--INSERT INTO #securable SELECT 'sysobjects','OBJECT','id'
INSERT INTO #securable SELECT 'database_principals','USER','principal_id','DATABASE_PRINCIPAL'
INSERT INTO #securable SELECT 'database_principals','ROLE','principal_id','DATABASE_PRINCIPAL'
INSERT INTO #securable SELECT 'database_principals','APPLICATION ROLE','principal_id','DATABASE_PRINCIPAL'
 
 
 
DECLARE securable_type_cursor CURSOR FOR
SELECT * FROM #securable
 
OPEN securable_type_cursor
FETCH NEXT FROM securable_type_cursor INTO @category, @securable_type, @col_name, @permission_class
WHILE @@FETCH_STATUS = 0
BEGIN
   
            DECLARE objlevel_cursor CURSOR FOR
            SELECT distinct --@sql_objpermission  = @sql_objpermission +
            'SELECT '''+dbname+''' as db_name, CASE b1.type WHEN ''R'' THEN ''ROLE'' WHEN ''A'' THEN ''APPLICATION ROLE'' WHEN ''S'' THEN ''USER'' END COLLATE '+collation_name+' +'' :: [''+b1.name+'']'' as obj_name,a.*, c.name as dbuser FROM ['+dbname+'].sys.database_permissions a
            inner join ['+dbname+'].sys.'+@category+' b1 on a.major_id = b1.'+@col_name+'
            left join ['+dbname+'].sys.database_principals c on a.grantee_principal_id = c.principal_id
            where grantee_principal_id = '+convert(varchar(10),principal_id) + ' AND major_id <> 0 AND minor_id = 0 and a.class_desc = '''+@permission_class+'''
 
            ' from #alldb_users_access a
           
            OPEN objlevel_cursor
            FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
            WHILE @@FETCH_STATUS = 0
            BEGIN
               
                  --PRINT @sql_objpermission
                  --EXEC(@sql_objpermission)
                  INSERT INTO #objpermission EXEC (@sql_objpermission)
                  FETCH NEXT FROM objlevel_cursor INTO @sql_objpermission
                  END
 
            CLOSE objlevel_cursor
            DEALLOCATE objlevel_cursor
 
    FETCH NEXT FROM securable_type_cursor INTO @category, @securable_type, @col_name, @permission_class
    END
 
CLOSE securable_type_cursor
DEALLOCATE securable_type_cursor
---------------------------------------------------------
--End of Database Principal Securable Handling
---------------------------------------------------------
 
---------------------------------------------------------
--End of New Securable Handling
---------------------------------------------------------
 
 
 
 
 
if NOT EXISTS (select 1 from #objpermission )
BEGIN
      PRINT '--NO object level permission granted for this login'
END
ELSE 
BEGIN
      DECLARE @print_objpermission varchar(300)
      DECLARE objperm_cursor CURSOR FOR
      --SELECT 'use ['+dbname+']'+char(10)+ state_desc +' '+permission_name + ' ON '+ obj_name + CASE state_desc WHEN 'DENY' THEN ' FROM ' ELSE ' TO ' END + '['+dbuser+']' FROM #objpermission WHERE state_desc <> 'GRANT_WITH_GRANT_OPTION' AND class_desc = 'OBJECT_OR_COLUMN'
      --UNION
      SELECT 'use ['+dbname+']'+char(10)+ state_desc +' '+permission_name + ' ON '+ obj_name + ' TO ['+dbuser+']' FROM #objpermission WHERE state_desc <> 'GRANT_WITH_GRANT_OPTION' --AND class_desc <> 'OBJECT_OR_COLUMN'
      UNION
      SELECT 'use ['+dbname+']'+char(10)+'GRANT '+permission_name + ' ON '+ obj_name + CASE state_desc WHEN 'DENY' THEN ' FROM ' ELSE ' TO ' END + '['+dbuser+'] WITH GRANT OPTION ' FROM #objpermission WHERE state_desc = 'GRANT_WITH_GRANT_OPTION'
 
      OPEN objperm_cursor
      FETCH NEXT FROM objperm_cursor INTO @print_objpermission
      WHILE @@FETCH_STATUS = 0
      BEGIN
            print @print_objpermission
            FETCH NEXT FROM objperm_cursor INTO @print_objpermission
      END
 
      CLOSE objperm_cursor
      DEALLOCATE objperm_cursor
END
 
--select * from #objpermission
 
 
----------------------------------------------
--database column permission to login
----------------------------------------------
PRINT ''
PRINT '--------------------------------------------------------------'
PRINT '--Grant/Revoking/Denying database column permission to login'
PRINT '---------------------------------------------------------------'
 
DECLARE @sql_colpermission varchar(max)
SET @sql_colpermission = ''
 
 
IF OBJECT_ID('tempdb..#colpermission') IS NOT NULL
BEGIN
      DROP TABLE #colpermission
END
CREATE TABLE #colpermission(
      [dbname] [sysname] NOT NULL,
      [col_name] [nvarchar](128) NULL,
      [obj_name] [nvarchar](128) NULL,
      [obj_owner] [nvarchar](128) NULL,
      [class] [tinyint] NOT NULL,
      [class_desc] [nvarchar](60) NULL,
      [major_id] [int] NOT NULL,
      [minor_id] [int] NOT NULL,
      [grantee_principal_id] [int] NOT NULL,
      [grantor_principal_id] [int] NOT NULL,
      [type] [char](4) NOT NULL,
      [permission_name] [nvarchar](128) NULL,
      [state] [char](1) NOT NULL,
      [state_desc] [nvarchar](60) NULL,
      [dbuser] [nvarchar](128) NULL
)
--PRINT (@sql_colpermission)
 
 
DECLARE collevel_cursor CURSOR FOR
SELECT distinct
'SELECT '''+dbname+''' as db_name, b.name as col_name, c.name as obj_name, e.name as obj_owner, a.*, d.name as dbuser FROM ['+dbname+'].sys.database_permissions a
inner join ['+dbname+'].sys.columns b on a.major_id = b.object_id and a.minor_id = b.column_id
left join ['+dbname+'].sys.sysobjects c on a.major_id = c.id
left join ['+dbname+'].sys.database_principals d on a.grantee_principal_id = d.principal_id
left join ['+dbname+'].sys.sysusers e on c.uid = e.uid
where grantee_principal_id = '+convert(varchar(10),principal_id) + ' AND major_id <> 0 AND major_id> 0 AND minor_id <> 0
' FROM #alldb_users_access
 
OPEN collevel_cursor
FETCH NEXT FROM collevel_cursor INTO @sql_colpermission
WHILE @@FETCH_STATUS = 0
BEGIN
   
    --INSERT INTO #dblevel (login_name, dbname, entity_name, subentity_name, permission_name) EXEC (@dblevel_sqlcmd)
    --PRINT @sql_colpermission
    INSERT INTO #colpermission EXEC (@sql_colpermission)
    FETCH NEXT FROM collevel_cursor INTO @sql_colpermission
    END
 
CLOSE collevel_cursor
DEALLOCATE collevel_cursor
 
if NOT EXISTS (select * from #colpermission )
BEGIN
      PRINT '--NO column level permission granted for this login'
END
ELSE
BEGIN
      DECLARE @print_colpermission varchar(300)
      DECLARE colperm_cursor CURSOR FOR
      SELECT 'use ['+dbname+']'+char(10)+replace(state_desc,'_',' ')+' '+permission_name + ' ON ['+ obj_owner + '].['+obj_name+ '] ('+ col_name+')'+CASE state_desc WHEN 'DENY' THEN ' FROM ' ELSE ' TO ' END + '['+dbuser+']' FROM #colpermission WHERE state_desc <> 'GRANT_WITH_GRANT_OPTION'
      UNION
      SELECT 'use ['+dbname+']'+char(10)+'GRANT '+permission_name + ' ON ['+ obj_owner + '].[' + obj_name +'] ('+ col_name+') ' + CASE state_desc WHEN 'DENY' THEN ' FROM ' ELSE ' TO ' END + '['+dbuser+'] WITH GRANT OPTION ' FROM #colpermission WHERE state_desc = 'GRANT_WITH_GRANT_OPTION'
 
      OPEN colperm_cursor
      FETCH NEXT FROM colperm_cursor INTO @print_colpermission
      WHILE @@FETCH_STATUS = 0
      BEGIN
            print @print_colpermission
            FETCH NEXT FROM colperm_cursor INTO @print_colpermission
      END
 
      CLOSE colperm_cursor
      DEALLOCATE colperm_cursor
END
 
--SELECT * FROM #colpermission