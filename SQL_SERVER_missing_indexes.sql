/*===================================================================================*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**************************************************************************************

This should be step TWO of the Tuning Lifecycle.  

The first step should be identifying unused indexes within the database, and taking action where necessary to address those indexes.

The third step in the Tuning Lifecycle is to observe the performance of the added/subtracted indexes, re-run these reports and act accordingly.


**************************************************************************************/
/*===================================================================================*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/************************************************************************************** 

The output of this query is SQL Server essentially looking at the statistics of all the queries run since the last server reboot, and SUGGESTING, 
"If there was an index here, I might perform a lot better".  

Bear in mind that none of our servers are regularly rebooted, and there is no other way to clear out the cached statistics that are being referenced

Understand that each index is another contributor to potential overhead, because SQL Server must maintain each of those indexes internally

Another example would be if there is an index that covers 3 columns on the table, each single update statement to a field contained within the index 
is going to require 3 times the disk I/O

Utilize the results generated from this process as an indication of where to start dedicating research/development efforts, 
*NOT* as a hard and fast directive to add the indexes suggested without further research

Column descriptions:

	Potential_Improvement_Measure - A general statistic illustrating the calculated improvement measure potentially gained by adding the suggested index.  
							  Considerations include but aren't limited to; disk I/O, physical/virtual memory, network throughput, etc
							  The higher the number, the greater the potential impact.

	Average_User_Impact - The average percent benefit that a user query could experience if the suggested index was added. 
					  The query cost would on average drop by the percentage returned in this column.
				  
	Table - the fully qualified name of the table (database.schema.table) the suggested index should be implemented on

	Equality_Columns - the columns in a table that are searched upon frequently using an "equality predicate" (i.e. an equal sign (=))

	Inequality_Columns - the columns in a table that are searched upon frequently using 
					 an "inequality predicate" (i.e. greater than/less than signs (<, >))
				 
	Included_Columns - List of columns suggested to be added as "included columns" to the index.  
				    A potential performance gain is achieved because the query optimizer can locate all the column values within the index.

	Create_Index_Statement - After a determination has been made about whether or not to implement the suggested indexes (and included columns), 
					   the value in this column can be copied and pasted to a query editor window and executed to actually create the suggested index

**************************************************************************************/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*===================================================================================*/

SELECT [Potential_Improvement_Measure] = ROUND((avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),0)
	,avg_user_impact as 'Average_User_Impact'
	,[statement] as 'Table'
	,mid.equality_columns as 'Equality_Columns'
	,mid.inequality_columns as 'Inequality_Columns'
	,mid.included_columns as 'Included_Columns' --Need to determine what the value being returned by this metric actually means
	,[Create_Index_Statement] = 'CREATE NONCLUSTERED INDEX ix_' + sys.objects.NAME 
	COLLATE DATABASE_DEFAULT + '_' + REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns, '') + ISNULL(mid.inequality_columns, ''), '[', ''), ']', ''), ', ', '_') + ' ON ' + [statement] + ' ( ' + IsNull(mid.equality_columns, '') 

	+ CASE 
		WHEN mid.inequality_columns IS NULL
			THEN ''
		ELSE CASE 
				WHEN mid.equality_columns IS NULL
					THEN ''
				ELSE ','
				END + mid.inequality_columns
		END + ' ) ' + CASE 
		WHEN mid.included_columns IS NULL
			THEN ''
		ELSE 'INCLUDE (' + mid.included_columns + ')'
		END + ';'

FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
	ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid
	ON mig.index_handle = mid.index_handle
INNER JOIN sys.objects WITH (NOLOCK)
	ON mid.OBJECT_ID = sys.objects.OBJECT_ID
WHERE (
		migs.group_handle IN (
			SELECT TOP (500) group_handle
			FROM sys.dm_db_missing_index_group_stats WITH (NOLOCK)
			ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC
			)
		)
	AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable') = 1
ORDER BY [Potential_Improvement_Measure] DESC
	,[Create_Index_Statement] DESC
	
	
	
	
	

	
	
	
	
	