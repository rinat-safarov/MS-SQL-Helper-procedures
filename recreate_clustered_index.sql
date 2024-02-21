CREATE UNIQUE CLUSTERED INDEX [PK_SomeTable]
    ON [dbo].[SomeTable] ([id] ASC)
WITH (DROP_EXISTING =  ON, ONLINE = ON )
ON [new_filegroup];
