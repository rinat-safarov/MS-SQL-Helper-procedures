IF OBJECT_ID('tempdb..#ind') IS NOT NULL
	DROP TABLE #ind
CREATE TABLE #ind(index_id INT, [object_id] INT, [name] SYSNAME NULL, fill_factor TINYINT, data_space_id INT, ind_type TINYINT)

INSERT INTO #ind
SELECT i.index_id, i.[object_id], i.name, i.fill_factor, i.data_space_id, i.[type]
FROM sys.indexes AS i
WHERE --1=1 OR 
i.[object_id] IN
	(
		0,
		OBJECT_ID('Orders.OrderDetails')
	)

SELECT	object_schema_name(ddius.[object_id]),
      	OBJECT_NAME(ddius.[object_id]),
      	i.ind_type,
      	ds.name 'data_space_name',
      	i.name,
      	ddips.avg_fragmentation_in_percent,
      	ddips.avg_page_space_used_in_percent,
      	ddips.record_count,
      	i.fill_factor,
      	ddips.page_count*8192/(1024*1024) 'ind_size(Mb)',
      	ddips.page_count*(100 - ddips.avg_page_space_used_in_percent)/100/128 'available_size(Mb)',
      	'ALTER INDEX '+ i.name + ' ON ' + object_schema_name(ddius.[object_id]) + '.' + OBJECT_NAME(ddius.[object_id]) + ' REORGANIZE --REBUILD PARTITION = ALL --WITH (ONLINE=ON)'
FROM	sys.dm_db_index_usage_stats ddius   
		JOIN	#ind i
			ON	i.[object_id] = ddius.[object_id]
			  	AND i.index_id = ddius.index_id   
		CROSS APPLY sys.dm_db_index_physical_stats(ddius.database_id, ddius.[object_id], i.index_id, NULL, 'sampled') ddips
		INNER JOIN sys.data_spaces AS ds
			ON ds.data_space_id = i.data_space_id
--WHERE (ddips.avg_fragmentation_in_percent > 10 OR ddips.avg_page_space_used_in_percent < 80) AND ddips.page_count*(100 - ddips.avg_page_space_used_in_percent)/100/128 > 50
--AND i.data_space_id = 4
ORDER BY	ddips.page_count*(100 - ddips.avg_page_space_used_in_percent) DESC
