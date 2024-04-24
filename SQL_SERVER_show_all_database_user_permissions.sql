-----------------------------------------------------------------------------
--- Rights Granted: Given a list of Users in the current database, return
---		the list of effective rights (including Deny) based on the Grants 
---		issued to the User, all Roles the User is a member of, membership
---		in fixed database Roles (e.g., db_datareader) and membership in any
---		fixed server roles.
-----------------------------------------------------------------------------

--- BUG/FEATURE: Doesn't account for the fact that each Login is de facto a member of Public.

set nocount on;

---------------------------------------
--- Declarations
---------------------------------------

declare
	@AllUsers	bit = 0,	--<<< SET THIS VALUE
							--	1 = Gather for ALL Users
							--	0 = Gather for explicit list in @Users table
	@ShowRaw	bit = 0,

	@PKey		int = 1,
	@MaxPKey	int = 0,

	@sqlStmt	nvarchar(max) = N'',
	@Login		sysname = N'',
	@template	nvarchar(max) = N'exec xp_logininfo ''<<UserName>>'', ''all''';

if object_id('tempdb..#loginInfo') is not null
	drop table #loginInfo;

create table #loginInfo (
	accountName		sysname,		-- Fully qualified Windows account name.
	type			char(8),		-- Type of Windows account. Valid values are user or group.
	privilege		char(9) null,	-- Access privilege for SQL Server. Valid values are admin, user, or null.
	MappedLoginName	sysname,		-- For user accounts that have user privilege, mapped login name 
									--	shows the mapped login name that SQL Server tries to use when 
									--	logging in with this account by using the mapped rules with 
									--	the domain name added before it.
	PermissionPath	sysname			-- Group membership that allowed the account access.
	);

declare @Users table (
	pkey		int identity(1, 1),
	UserName	sysname
	)

---------------------------------------
--- Define the User(s) of interest
---------------------------------------

insert into @Users (UserName)
values
	--('role_DenyWrite'),			--<<< Populate with a list of Users or Roles
	--('XYZ\WINDOWSGROUP'),
	('XYZ\WINDOWSUSER'),
	--('SqlLogin'),
	('public')

set @MaxPKey = @@rowcount;

-----------------------------------------------------------------------------
--- Find Logins that are members of Windows Groups and add the Group to the 
---	set of Logins
-----------------------------------------------------------------------------

while (@PKey <= @MaxPKey)
begin
	select @Login = UserName
	from @Users
	where pkey = @PKey

	if exists(select *
			from sys.server_principals sp
			where sp.name = @Login
			and sp.type = 'U'
			) 
		or
		not exists(select *
			from sys.server_principals sp
			where sp.name = @Login
			) 
	begin
		set @sqlStmt = replace(@template, '<<UserName>>', @Login);

		truncate table #loginInfo;

		insert into #loginInfo (
			accountName,
			type,
			privilege,
			MappedLoginName,
			PermissionPath
			)
		exec sp_ExecuteSQL @sqlStmt

		--/**/select * from #loginInfo;

		insert into @Users(UserName)
		select l.PermissionPath
		from #loginInfo l
		left outer join
			@Users u
				on	u.UserName = l.PermissionPath
				and	l.type = 'user'
		where
			u.UserName is null
	end

	set @PKey += 1;
end

--/**/select 'Agg Users' Label, * from @Users

-----------------------------------------------------------------------------

if @ShowRaw = 1
begin
	select
		@@servername SrvName,
		db_name() DbName,
		d.name dn,
		s.sid ServerSID,
		d.sid DB_SID,
		case
			when s.sid = d.sid then 1
			else 0
			end is_equal
	from
		sys.server_principals s
	inner join
		sys.database_principals d
			on d.name = s.name
	where
		@AllUsers = 1
		or
		s.Name in (
			select UserName
			from @Users
			)
end

-----------------------------------------------------------------------------

;with AllRoles	-- Recursively find all Roles the Users are members of
as	(
	select
		dp.principal_id,
		dp.name,
		dp.sid,
		cast('' as sysname) MemberName,
		cast(dp.name as sysname) Lineage,
		dp.name BaseName
	from sys.database_principals dp
	left outer join sys.server_principals sp
		on	dp.sid = sp.sid
	--where
	--	dp.type in ('S', 'U', 'G')
	--or	dp.name = 'public'			-- Public is special since it is not in sys.database_role_members

	union all

	select 
		r.principal_id, 
		r.name,
		r.sid, 
		rm.Name, 
		cast(r.Name + N'.' + Lineage as sysname), 
		ar.BaseName
	from
		AllRoles ar
	inner join
		sys.database_role_members drm
			on	drm.member_principal_id = ar.principal_id
	inner join
		sys.database_principals r
			on	r.principal_id = drm.role_principal_id
	inner join
		sys.database_principals rm
			on	rm.principal_id = drm.member_principal_id
)
select a.*
from (
	-------------------------------------------
	--- Object Level Rights: Explicit Grants
	---	(Based on User and Role Memberships)
	-------------------------------------------

	SELECT 'Explicit Grants' How,
		coalesce(so.name, '.') AS 'Object Name', 

		sp.permission_name,
		state_desc,

		u.Name Grantee,
		ar.Lineage,
		ar.BaseName
	FROM
		sys.database_permissions sp					-- Rights Granted
	inner join
		sys.database_principals u					-- Grantee
			on	sp.grantee_principal_id = u.principal_id

	left outer join
		sys.objects so								-- Object
			on	so.object_id = sp.major_id

	inner join
		AllRoles ar
			on	u.sid = ar.sid

	WHERE 
		(
		so.name is Null
	or
		LEFT(so.name,3) NOT IN ('sp_', 'fn_', 'dt_', 'dtp', 'sys')
		--AND
		--so.type IN ('U','V','TR','P','FN','IF','TF')
		)
	--and	not (
	--		sp.class_desc = 'DATABASE'
	--	and sp.permission_name = 'CONNECT'
	--	)
	and	sp.major_id >= 0					-- Negative => System Object
	and (
		ar.BaseName = 'public'
		or
		@AllUsers = 1
		or
		ar.BaseName in (
			select UserName
			from @Users
			)
		)

	union --all

	-------------------------------------------
	--- Fixed Database Role Membership
	-------------------------------------------

	select 'Fixed Database Role' How,
		ar.Name,
		'.',
		'.',
		ar.MemberName,
		ar.Lineage,
		ar.BaseName
	from
		AllRoles ar
	inner join
		sys.database_principals r
			on	r.principal_id = ar.principal_id
			and	r.is_fixed_role = 1
	where
		@AllUsers = 1
		or
		ar.BaseName in (
			select UserName
			from @Users
			)

	union --all

	-------------------------------------------
	--- Fixed Server Role Membership
	-------------------------------------------

	select 'Fixed Server Role' How,
		sr.Name,
		'.',
		'.',
		'Server Role',
		'.',
		l.Name
	from sys.server_principals l
	inner join
		sys.server_role_members r
	on
		r.member_principal_id = l.principal_id
	inner join
		sys.server_principals sr
	on
		sr.principal_id = r.role_principal_id
	and	sr.type = 'R'
	where
		@AllUsers = 1
		or
		l.name in (
				select UserName
				from @Users
				)

	union --all

	-------------------------------------------
	--- Explicit Server Level Rights
	---	(Based on Login)
	-------------------------------------------

	select 'Explicit Server: Login' How,
		'Server',
		sp.permission_name,
		sp.state_desc,
		l.Name,
		'.',
		l.Name
	from
		sys.server_permissions sp				-- Rights Granted
	inner join
		sys.server_principals l					-- Grantee
			on	sp.grantee_principal_id = l.principal_id
	where
		sp.permission_name <> 'CONNECT SQL'
	and	(
		@AllUsers = 1
		or
		l.name in (
				select UserName
				from @Users
				)
		)

	union --all

	-------------------------------------------
	--- Explicit Server Level Rights
	---	(Based on Login -> Server Role)
	-------------------------------------------

	select 'Explicit Server: Role' How,
		'Server',
		sp.permission_name,
		sp.state_desc,
		l.Name,
		'.',
		l.Name
	from
		sys.server_permissions sp				-- Rights Granted
	inner join
		sys.server_principals sr
			on	sp.grantee_principal_id = sr.principal_id
			and	sr.type = 'R'					-- Grantee is Server Role
	inner join
		sys.server_role_members srm
			on	sr.principal_id = srm.role_principal_id
	inner join
		sys.server_principals l					-- Login is member of Role
			on	srm.member_principal_id = l.principal_id
	where
		sp.permission_name <> 'CONNECT SQL'
	and	(
		@AllUsers = 1
		or
		l.name in (
				select UserName
				from @Users
				)
		)
	) a
order by
	BaseName,
	case
		when permission_name = '' then 1 else 2 end,
	[Object Name],
	permission_name,
	state_desc,
	Grantee
