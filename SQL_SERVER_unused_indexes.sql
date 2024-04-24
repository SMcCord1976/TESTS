/*===================================================================================*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**************************************************************************************

This should be step ONE of the Tuning Lifecycle. 


**************************************************************************************/
/*===================================================================================*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/************************************************************************************** 

The output of this query is SQL Server essentially looking at the statistics of all the queries run since the last server reboot, and outlining 
which indexes have a low read vs. write ratio.  Indexes are useful for the retrieval (reading) of data.  


Utilize the results generated from this process as an indication of where to start dedicating research/development efforts, 
*NOT* as a hard and fast directive to remove the indexes as suggested without further research

Column descriptions:
	
	Database_Name - The name of the database on which the objects reside

	Object_Name - The object on which the index resides

	Index_Name - The name of the index
				  
	Reads - The number of reads generated using the columns contained in the index

	Writes - The number of writes to columns contained in the index 
	
	rows - The number of rows in the table

	Reads_Per_Writes - The percentage of reads per writes.  Keep in mind that indexes are extremely useful for data retrieval, 
				    but are a performance inhibitor to inserts, updates and deletes.  Therefore an index with a LOW number of reads, but a HIGH
				    number of writes is quite possibly an unnecessary index
					 
	Drop_Index_Statement - After a determination has been made about whether or not to remove the suggested indexes, 
					   the value in this column can be copied and pasted to a query editor window and executed to actually drop 
					   the suggested index

**************************************************************************************/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#**#*/
/*#*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##*##**/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*===================================================================================*/







SELECT 
	db_name () as 'Database Name'
	,o.NAME AS 'Object_Name'
	,i.NAME AS 'Index_Name'
	--, i.index_id as 'Index_ID'   
	,user_seeks + user_scans + user_lookups AS 'Reads'
	,user_updates AS 'Writes'
	,rows = (
		SELECT SUM(p.rows)
		FROM sys.partitions p
		WHERE p.index_id = s.index_id
			AND s.object_id = p.object_id
		)
	,CASE 
		WHEN s.user_updates < 1
			THEN 100
		ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
		END AS Reads_Per_Writes
	,'DROP INDEX ' + QUOTENAME(i.NAME) + ' ON ' + QUOTENAME(c.NAME) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) AS 'Drop_Index_Statement'
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i
	ON i.index_id = s.index_id
		AND s.object_id = i.object_id
INNER JOIN sys.objects o
	ON s.object_id = o.object_id
INNER JOIN sys.schemas c
	ON o.schema_id = c.schema_id
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
	AND s.database_id = DB_ID()
	AND i.type_desc = 'nonclustered'
	AND i.is_primary_key = 0
	AND i.is_unique_constraint = 0
	AND (
		SELECT SUM(p.rows)
		FROM sys.partitions p
		WHERE p.index_id = s.index_id
			AND s.object_id = p.object_id
		) > 10000
--	AND o.NAME = 'TIM_PurchaseOffer'
ORDER BY Reads