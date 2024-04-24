

/** THIS PROCEDURE RELIES UPON THE EXISTENCE OF THE sp_hexadecimal STORED PROCEDURE **/


----------------------------------------------
--Login Pre-requisites
----------------------------------------------
/****** SUPPLY LOGIN NAME BELOW ******/


set concat_null_yields_null off
USE master
go
SET NOCOUNT ON
DECLARE @login_name varchar(100)
SET @login_name = 'LOGIN' --<< SUPPLY LOGIN NAME HERE
 
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
 
DECLARE @name sysname, @dbname sysname, @schema sysname, @dbuser_cmd varchar(8000)
DECLARE dbuser_cursor CURSOR FAST_FORWARD FOR
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
GO
' FROM #alldb_users WHERE name = @name and dbname = @dbname
END
ELSE
BEGIN
SELECT @dbuser_cmd = 'USE ['+dbname+']
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '''+name+''')
BEGIN
          CREATE USER ['+@name+'] FOR LOGIN ['+@login_name+']
END
GO
' FROM #alldb_users WHERE name = @name and dbname = @dbname
END
 
          print @dbuser_cmd
    FETCH NEXT FROM dbuser_cursor INTO @dbname, @name, @schema
    END
 
CLOSE dbuser_cursor
DEALLOCATE dbuser_cursor
 
----------------------------------------------
--Create DB Role Temp table
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
 
---------------------------------------------------------------------------------------
--                                                       Grant all securable class to login
----------------------------------------------------------------------------------------
PRINT ''
PRINT '----------------------------------------------'
PRINT '--Grant all securable class to login '
PRINT '----------------------------------------------'
 
 
IF OBJECT_ID('tempdb..#securable_class') is not null
BEGIN
          DROP TABLE #securable_class
END
 
IF OBJECT_ID('tempdb..#dblevel') is not null
BEGIN
          DROP TABLE #dblevel
END
create table #dblevel (login_name varchar(256), dbname sysname, dbuser_name varchar(100), class_desc varchar(100), permission_name varchar(100), state_desc varchar(100))
 
DECLARE @dblevel_sqlcmd varchar(1000)
DECLARE dblevel_cursor CURSOR FAST_FORWARD FOR
SELECT 'select '''+@login_name+''' as login_name, '''+dbname+''' as dbname, b.name as dbuser_name, a.class_desc, a.permission_name, state_desc from ['+dbname+'].sys.database_permissions a inner join ['+dbname+'].sys.database_principals b
on a.grantee_principal_id = b.principal_id
where b.name in (''public'','''+name+''') and class_desc = ''DATABASE'''
FROM #alldb_users_access
union
SELECT 'select '''+@login_name+''' as login_name, ''master'' as dbname, b.name as dbuser_name, a.class_desc, a.permission_name, state_desc from sys.server_permissions a inner join sys.server_principals b
on a.grantee_principal_id = b.principal_id
where b.name = '''+@login_name+''''
UNION
SELECT 'select '''+@login_name+''' as login_name, ''master'' as dbname, b.name as dbuser_name, a.class_desc, a.permission_name, state_desc from sys.server_permissions a inner join sys.server_principals b
on a.grantee_principal_id = b.principal_id and class_desc = ''SERVER''
where b.name = ''public'''
 
OPEN dblevel_cursor
FETCH NEXT FROM dblevel_cursor INTO @dblevel_sqlcmd
WHILE @@FETCH_STATUS = 0
BEGIN
   
    INSERT INTO #dblevel (login_name, dbname, dbuser_name, class_desc, permission_name, state_desc) EXEC (@dblevel_sqlcmd)
    FETCH NEXT FROM dblevel_cursor INTO @dblevel_sqlcmd
    END
 
CLOSE dblevel_cursor
DEALLOCATE dblevel_cursor
 
SET NOCOUNT ON
 
DELETE FROM #dblevel WHERE permission_name IN ('SELECT','INSERT','UPDATE','DELETE','REFERENCES')
DELETE FROM #dblevel WHERE dbname IN (SELECT dbname FROM #dbrole WHERE sid = @login_sid AND dbrole = 'db_owner')
 
DECLARE @securable_sqlcmd varchar(150)
DECLARE securable_cursor CURSOR FAST_FORWARD FOR
SELECT distinct 'USE ['+dbname+']
GRANT '+permission_name+' TO ['+@login_name+']
GO
' FROM #dblevel
 
OPEN securable_cursor
FETCH NEXT FROM securable_cursor INTO @securable_sqlcmd
WHILE @@FETCH_STATUS = 0
BEGIN
          PRINT @securable_sqlcmd
          FETCH NEXT FROM securable_cursor INTO @securable_sqlcmd
END
CLOSE securable_cursor
DEALLOCATE securable_cursor
 