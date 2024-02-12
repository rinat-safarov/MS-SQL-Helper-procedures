IF OBJECT_ID('tempdb..#ind') IS NOT NULL
	DROP TABLE #ind
CREATE TABLE #ind(index_id INT, [object_id] INT, [name] SYSNAME NULL, fill_factor TINYINT, data_space_id INT, ind_type TINYINT)

INSERT INTO #ind
SELECT i.index_id, i.[object_id], i.name, i.fill_factor, i.data_space_id, i.[type]
from sys.dm_db_index_usage_stats ddius
inner join sys.indexes i on i.object_id=ddius.object_id and i.index_id=ddius.index_id
where ddius.last_user_seek is null
  and ddius.last_user_scan is null
  and ddius.last_user_lookup is null
 
SELECT	object_schema_name(ddius.[object_id])+'.'+OBJECT_NAME(ddius.[object_id]),
      	OBJECT_NAME(ddius.[object_id]),
      	i.ind_type,
      	ds.name 'data_space_name',
      	i.name,
      	ddips.page_count*8192/(1024*1024) 'ind_size(Mb)',
      	ddips.page_count*(100 - ddips.avg_page_space_used_in_percent)/100/128 'available_size(Mb)',
      	ddips.record_count,
      	i.fill_factor,
		'DROP INDEX ' + i.name + ' ON ' + object_schema_name(ddius.[object_id]) + '.' + OBJECT_NAME(ddius.[object_id])
      	--'ALTER INDEX '+ i.name + ' ON ' + object_schema_name(ddius.[object_id]) + '.' + OBJECT_NAME(ddius.[object_id]) + ' REORGANIZE --REBUILD PARTITION = ALL --WITH (ONLINE=ON)'
FROM	sys.dm_db_index_usage_stats ddius   
		JOIN	#ind i
			ON	i.[object_id] = ddius.[object_id]
			  	AND i.index_id = ddius.index_id   
		CROSS APPLY sys.dm_db_index_physical_stats(ddius.database_id, ddius.[object_id], i.index_id, NULL, 'sampled') ddips
		INNER JOIN sys.data_spaces AS ds
			ON ds.data_space_id = i.data_space_id
WHERE 1=1
AND (OBJECT_NAME(ddius.[object_id]) not like '%_not_use'
  AND i.name  not like '%_not_use')
  --and ind_type <> 1
-- (ddips.avg_fragmentation_in_percent > 10 OR ddips.avg_page_space_used_in_percent < 80) AND ddips.page_count*(100 - ddips.avg_page_space_used_in_percent)/100/128 > 50
-- AND i.data_space_id = 4
ORDER BY	--1,2
ddips.page_count DESC