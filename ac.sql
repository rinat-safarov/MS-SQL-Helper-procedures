CREATE PROCEDURE dbo.ac
AS
DECLARE @curdate DATETIME = GETDATE()
SELECT	ss.Host_Name,
		ss.login_name,
		d.name,
		command,
		r.[status],
		ss.session_id             sess_id,
		r.blocking_session_id,
		percent_complete          perc_compl,
		CAST(((DATEDIFF(s, start_time, @curdate)) / 3600) AS VARCHAR) + ':'
		+ CAST((DATEDIFF(s, start_time, @curdate)%3600) / 60 AS VARCHAR) + ':'
		+ CAST((DATEDIFF(s, start_time, @curdate)%60) AS VARCHAR) AS 
		running_time,
		DATEADD(second, estimated_completion_time / 1000, @curdate) AS 
		est_completion_time,
		CAST((estimated_completion_time / 3600000) AS VARCHAR) + ':'
		+ CAST((estimated_completion_time %3600000) / 60000 AS VARCHAR) + ':'
		+ CAST((estimated_completion_time %60000) / 1000 AS VARCHAR) AS 
		est_time_to_go,
		start_time,
		r.wait_type,
		object_schema_name(s.objectid, s.dbid)+'.'+OBJECT_NAME(s.objectid, s.dbid),
		s.text,
		ss.program_name
FROM	sys.dm_exec_requests r   
		JOIN	sys.databases  AS d
			ON	d.database_id = r.database_id   
		OUTER APPLY sys.dm_exec_sql_text(r.sql_handle)s
LEFT JOIN	sys.dm_exec_Sessions ss
			ON	ss.session_id = r.session_id
WHERE	r.sql_handle IS NOT       NULL
ORDER BY
	r.start_time
GO
