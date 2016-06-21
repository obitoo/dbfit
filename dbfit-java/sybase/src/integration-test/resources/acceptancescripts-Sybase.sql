
------------------------------------------------
-- Create databases
------------------------------------------------
CREATE DATABASE FitNesseTestDB
go

CREATE DATABASE FitNesseTestDB2
go


------------------------------------------------
-- Create user
------------------------------------------------
CREATE LOGIN FitNesseUser WITH PASSWORD FitNesseUser   default database FitNesseTestDB
go
GRANT ROLE sa_role TO FitNesseUser
go

USE FitNesseTestDB
go
sp_adduser FitNesseUser
go
GRANT all TO FitNesseUser
go

USE FitNesseTestDB2
go
sp_adduser FitNesseUser
go
GRANT all TO FitNesseUser
go


------------------------------------------------
--  Objects - first Db
------------------------------------------------

USE FitNesseTestDB
go

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'users' AND type in ('U'))
BEGIN
CREATE TABLE users(
        Name     varchar(50) NULL,
        UserName varchar(50) NULL,
        UserId   int         IDENTITY NOT NULL
)
END
go


CREATE PROCEDURE MakeUser AS
begin
        insert into users (Name, UserName) values ('user1', 'fromproc')
end
go

EXEC sp_procxmode MakeUser , anymode






CREATE PROCEDURE CalcLength_P (@name      VARCHAR(255) , @strlength INT OUTPUT)
AS
BEGIN
	SET @strlength = len(@name)
END
go
EXEC sp_procxmode CalcLength_P , anymode
go

CREATE PROCEDURE Increment_P @counter INT OUTPUT
AS
BEGIN
	SET @counter = ISNULL(@counter, 1) + 1
END
go
EXEC sp_procxmode Increment_P , anymode
go


CREATE FUNCTION dbo.Multiply(@n1 int, @n2 int) RETURNS int 
AS
BEGIN
   declare @num3 int
   set @num3 = @n1*@n2
   return @num3
END
go



CREATE PROCEDURE MultiplyIO(@factor int, @val int output)
AS
BEGIN
	set @val = @factor*@val
END
go

EXEC sp_procxmode MultiplyIO , anymode
go


CREATE PROCEDURE TestProc2 ( @iddocument int, @iddestination_user int)
AS
BEGIN
declare @errorsave int

set @errorsave = 0

if (@iddocument < 100)
begin
	set @errorsave = 53120
	raiserror @errorsave, 15, 1, 'Custom error message' 
	return @errorsave
end
END
go
EXEC sp_procxmode TestProc2 , anymode
go

sp_addmessage @message_num = 53120, @severity=1, @message_text = 'test user defined error msg'
go


drop procedure ListUsers_P
go
CREATE PROCEDURE ListUsers_P (@howmuch int )
AS
BEGIN
   declare @sql varchar(255)
   select @sql = 'select top '+convert(varchar,@howmuch)+' * from users order by UserId'
   exec (@sql)
END
go
EXEC sp_procxmode ListUsers_P , anymode
go

DROP PROCEDURE TestDecimal
go
CREATE PROCEDURE TestDecimal (
                                @inParam decimal(15, 8),
                                @copyOfInParam decimal(15, 8) output,
                                @constOutParam decimal(15, 8) output
                             )
as
begin
   set @copyOfInParam = @inParam
   set @constOutParam = 123.456
end
go
EXEC sp_procxmode TestDecimal , anymode
go




------------------------------------------------
--  Objects - second Db
------------------------------------------------
USE FitNesseTestDB2
go

CREATE TABLE dbo.Users2 (
    Name     VARCHAR(50) NULL,
    UserName VARCHAR(50) NULL,
    UserId   INT IDENTITY NOT NULL
)
go

CREATE PROCEDURE dbo.MakeUser2
AS
BEGIN
    INSERT
      INTO Users2
           (
           Name
         , UserName
           )
    VALUES (
           'user1'
         , 'fromproc'
           )
END
go

EXEC sp_procxmode MakeUser2 , anymode
go


--- EOF
--- EOF
--- EOF - Non-ported Sql server code below here




IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReturnUserTable_F]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[ReturnUserTable_F]
(
	@howmuch int
)
RETURNS 
@userTable TABLE 
(
	-- Add the column definitions for the TABLE variable here
	[user] varchar(50), 
	[username] varchar(255)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	DECLARE @i INT
	SET @i = 0
	WHILE (@i < @howmuch)
	BEGIN
		SET @i = @i + 1
		INSERT @userTable([user], [username])
			VALUES(''User '' + CAST(@i AS VARCHAR(10)), ''Username '' + CAST(@i AS VARCHAR(10)))
	END
	
	RETURN 
END
' 
END

go
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConcatenateStrings_P]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[ConcatenateStrings_P]
@firstString varchar(255)
,@secondString varchar(255)
,@concatenated varchar(600) output
AS
BEGIN
	SET @concatenated = @firstString + '' '' + @secondString
END
' 
END
go
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConcatenateStrings_F]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [dbo].[ConcatenateStrings_F]
(
@firstString varchar(255)
,@secondString varchar(255)
)
RETURNS VARCHAR(600)
AS
BEGIN
	DECLARE @concatenated VARCHAR(600)
	SET @concatenated = @firstString + '' '' + @secondString
	RETURN @concatenated
END
' 
END

go








IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateUserTable_P]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[PopulateUserTable_P]
@howmuch INT
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	DECLARE @i INT
	SET @i = 0
	WHILE (@i < @howmuch)
	BEGIN
		SET @i = @i + 1
		INSERT [Users]([name], [username])
			VALUES(''User '' + CAST(@i AS VARCHAR(10)), ''Username '' + CAST(@i AS VARCHAR(10)))
	END
END
' 
END
go
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OpenCrsr_P]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[OpenCrsr_P]
@howmuch INT,
@OutCrsr CURSOR VARYING OUTPUT
AS
BEGIN
	SET @OutCrsr = CURSOR FOR
	SELECT TOP (@howmuch) [name], [username], [userid]
	FROM [Users];

	OPEN @OutCrsr;
END
' 
END
go
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeleteUserTable_P]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[DeleteUserTable_P]
AS
DELETE [Users];
' 
END
