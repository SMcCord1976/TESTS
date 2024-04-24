/*  
	DATE:  20190421
	AUTHOR:  SMcCord
	USAGE:  T-SQL Editor interface for SQL Replication Monitor.
			Run on distributor instance, distribution database.
	CAVEAT:  Server / Instance names with a hyphen / dash present in them will break the charindex chain for the 
	[PublisherInstance - PublisherDB - Publication - SubscriberInstance - AgentID] column.  
	Evaluate and verify results carefully
*/


USE [distribution]
GO


SELECT 
	(CASE
		WHEN mdh.runstatus = '1' THEN 'START - ' + CAST(mdh.runstatus as VARCHAR)
		WHEN mdh.runstatus = '2' THEN 'SUCCESS - ' + CAST(mdh.runstatus as VARCHAR)
		WHEN mdh.runstatus = '3' THEN 'IN_PROGRESS - ' + CAST(mdh.runstatus as VARCHAR)
		WHEN mdh.runstatus = '4' THEN 'IDLE - ' + CAST(mdh.runstatus as VARCHAR)
		WHEN mdh.runstatus = '5' THEN 'RETRY - ' + CAST(mdh.runstatus as VARCHAR)
		WHEN mdh.runstatus = '6' THEN 'FAIL - ' + CAST(mdh.runstatus as VARCHAR)
		ELSE CAST(mdh.runstatus as VARCHAR)
	END) [run_status]
,mda.name [PublisherInstance - PublisherDB - Publication - SubscriberInstance - AgentID]
,mda.publisher_db [publisher_db]
,mda.publication [publication_name]
,REVERSE(SUBSTRING(REVERSE(mda.name)
,CHARINDEX('-',REVERSE(mda.name))+1
,CHARINDEX('-',REVERSE(mda.name)
,CHARINDEX('-',REVERSE(mda.name))+1)-CHARINDEX('-',REVERSE(mda.name))-1)) [subscriber_instance] 
,mda.subscriber_db [subscriber_db]
,CONVERT(VARCHAR(25),mdh.[time]) [last_sync_time]
,und.undelivered_commands_in_distribution1 [undelivered_commands_in_distribution]
,mdh.comments [comments]
,'SELECT * FROM distribution.dbo.msrepl_errors (NOLOCK) WHERE id = ' + CAST(mdh.error_id AS VARCHAR(8)) [if_error_run_query_for_more_info]
	,(CASE
		WHEN mda.subscription_type = '0' THEN 'PUSH'
		WHEN mda.subscription_type = '1' THEN 'PULL'
		WHEN mda.subscription_type = '2' THEN 'ANONYMOUS'
		ELSE CAST(mda.subscription_type AS VARCHAR)
	END) [subscription_type]
,mdh.xact_seqno [sequence_id]
FROM distribution.dbo.MSdistribution_agents mda
	LEFT JOIN distribution.dbo.MSdistribution_history mdh
		ON mdh.agent_id = mda.id
	JOIN
		(
		SELECT mss.agent_id, max_agent_value.[time]
		, SUM(CASE WHEN xact_seqno > max_agent_value.maxseq THEN 1 ELSE 0 END) AS [undelivered_commands_in_distribution1]
		FROM distribution.dbo.MSrepl_commands msc (NOLOCK)
		JOIN distribution.dbo.MSsubscriptions AS mss (NOLOCK) 
			ON (msc.article_id = mss.article_id AND msc.publisher_database_id = mss.publisher_database_id)
		JOIN 
				(
			SELECT hist.agent_id, MAX(hist.[time]) AS [time], h.maxseq
			FROM distribution.dbo.MSdistribution_history hist (NOLOCK)
			JOIN 
				(SELECT agent_id, ISNULL(MAX(xact_seqno),0x0) AS maxseq
				FROM distribution.dbo.MSdistribution_history (NOLOCK)
				GROUP BY agent_id) AS h
				ON (hist.agent_id = h.agent_id AND h.maxseq=hist.xact_seqno)
			GROUP BY hist.agent_id, h.maxseq
				) AS max_agent_value
		ON max_agent_value.agent_id = mss.agent_id
		GROUP BY mss.agent_id, max_agent_value.[time]
		) und
	ON mda.id = und.agent_id  
	AND und.[time] = mdh.[time]
	WHERE mda.subscriber_db <> 'virtual'  
ORDER BY mdh.[time]

