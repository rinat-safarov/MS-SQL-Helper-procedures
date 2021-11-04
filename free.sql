USE [master]
GO

/****** Object:  StoredProcedure [dbo].[Free]    Script Date: 10.08.2020 14:05:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Free]
AS
create TABLE #res (DatabaseName sysname, FILENAME VARCHAR(128), Physical_Name VARCHAR(128), FileGroupName varchar(128), MaxSize INT, TotalSize INT, Available INT, AvailablePercent INT)

DECLARE @command varchar(1000)

SELECT @command = 'IF ''?'' NOT IN(''model'', ''master'', ''msdb'') BEGIN USE [?]
insert into #res
SELECT ''?'', df.name AS FILENAME, df.physical_name, f.name FileGroupName, df.max_size/128, ddfsu.total_page_count/128 [Total Size], 
(ddfsu.unallocated_extent_page_count/128) available, 
(ddfsu.unallocated_extent_page_count*100/ddfsu.total_page_count) available_percent
  FROM sys.dm_db_file_space_usage AS ddfsu
JOIN sys.filegroups AS f ON f.data_space_id = ddfsu.[filegroup_id]
JOIN sys.database_files AS df ON df.[file_id] = ddfsu.[file_id]
END'
EXEC sp_MSforeachdb @command

SELECT @command = 'IF ''?'' NOT IN(''model'', ''master'', ''msdb'') BEGIN USE [?]
insert into #res
SELECT ''?'', df.name AS FILENAME, df.physical_name, NULL,
 0, total_log_size_in_bytes/1024/1024 [Total Size],
  (total_log_size_in_bytes -used_log_space_in_bytes)/1024/1024 Available,
  100 - used_log_space_in_bytes*100/total_log_size_in_bytes available_percent
FROM sys.dm_db_log_space_usage AS ddlsu
join sys.database_files AS df ON df.[type] = 1
END'
EXEC sp_MSforeachdb @command

--SELECT * FROM #res WHERE Physical_Name LIKE 'D:\%' ORDER BY TotalSize
SELECT * FROM #res ORDER BY Available desc
DROP TABLE #res

--SELECT * FROM sys.database_files

--SELECT * FROM sys.dm_db_log_space_usage

--SELECT * FROM sys.database_files
--USE tempdb; DBCC shrinkfile('temp7')

GO

