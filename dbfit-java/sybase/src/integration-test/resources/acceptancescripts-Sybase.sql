
-- Create databases
CREATE DATABASE FitNesseTestDB
go

CREATE DATABASE FitNesseTestDB2
go


-- Create user
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


--  Objects - first Db

USE FitNesseTestDB
go

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'users' AND type in ('U'))
BEGIN
CREATE TABLE users(
        name     varchar(50) NULL,
        username varchar(50) NULL,
        userid   int         IDENTITY NOT NULL
)
END
go


CREATE PROCEDURE MakeUser AS
begin
        insert into users (name, username) values ('user1', 'fromproc')
end
go

CREATE PROCEDURE calclength_p @name      VARCHAR(255)
                            , @strlength INT OUTPUT
AS
BEGIN
	SET @strlength = len(@name)
END
go

CREATE PROCEDURE increment_p @counter INT OUTPUT
AS
BEGIN
	SET @counter = ISNULL(@counter, 1) + 1
END
go

CREATE FUNCTION dbo.Multiply(@n1 int, @n2 int) RETURNS int 
AS
BEGIN
   declare @num3 int
   set @num3 = @n1*@n2
   return @num3
END
go





--  Objects - second Db
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
--- EOF






IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalcLength_P]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[CalcLength_P]
@name VARCHAR(255)
, @strlength INT OUTPUT
AS
BEGIN
	SET @strlength = DataLength(@name);
END;
' 
END
go
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

CREATE PROCEDURE [dbo].[TestProc2]
	@iddocument int,
	@iddestination_user int
as
declare @errorsave int

set @errorsave = 0

if (@iddocument < 100)
begin
	set @errorsave = 53120
	raiserror(@errorsave, 15, 1, 'Custom error message')
	return @errorsave
end

sp_addmessage @msgnum = 53120, @severity=1, @msgtext = 'test user defined error msg' 

CREATE procedure [dbo].[ListUsers_P] @howmuch int AS
BEGIN
select top (@howmuch) * from users order by userid
END;

create procedure MultiplyIO(@factor int, @val int output) as
begin
	set @val = @factor*@val;
end;

create procedure TestDecimal
@inParam decimal(15, 8),
@copyOfInParam decimal(15, 8) out,
@constOutParam decimal(15, 8) out
as
begin
set @copyOfInParam = @inParam
set @constOutParam = 123.456;
end
