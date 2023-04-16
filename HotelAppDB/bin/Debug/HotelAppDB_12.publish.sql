﻿/*
Deployment script for HotelDB

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "HotelDB"
:setvar DefaultFilePrefix "HotelDB"
:setvar DefaultDataPath "C:\ProgramData\SOLIDWORKS Electrical\MSSQL12.TEW_SQLEXPRESS\MSSQL\DATA\"
:setvar DefaultLogPath "C:\ProgramData\SOLIDWORKS Electrical\MSSQL12.TEW_SQLEXPRESS\MSSQL\DATA\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET ANSI_NULLS ON,
                ANSI_PADDING ON,
                ANSI_WARNINGS ON,
                ARITHABORT ON,
                CONCAT_NULL_YIELDS_NULL ON,
                QUOTED_IDENTIFIER ON,
                ANSI_NULL_DEFAULT ON,
                CURSOR_DEFAULT LOCAL,
                RECOVERY FULL 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET PAGE_VERIFY NONE 
            WITH ROLLBACK IMMEDIATE;
    END


GO
PRINT N'Creating Table [dbo].[Bookings]...';


GO
CREATE TABLE [dbo].[Bookings] (
    [Id]        INT   IDENTITY (1, 1) NOT NULL,
    [RoomId]    INT   NOT NULL,
    [GuestId]   INT   NOT NULL,
    [StartDate] DATE  NOT NULL,
    [EndDate]   DATE  NOT NULL,
    [CheckedIn] BIT   NOT NULL,
    [TotalCost] MONEY NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Table [dbo].[Guests]...';


GO
CREATE TABLE [dbo].[Guests] (
    [Id]        INT           IDENTITY (1, 1) NOT NULL,
    [FirstName] NVARCHAR (50) NOT NULL,
    [LastName]  NVARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Table [dbo].[Rooms]...';


GO
CREATE TABLE [dbo].[Rooms] (
    [Id]         INT          IDENTITY (1, 1) NOT NULL,
    [RoomNumber] VARCHAR (10) NOT NULL,
    [RoomTypeId] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Table [dbo].[RoomTypes]...';


GO
CREATE TABLE [dbo].[RoomTypes] (
    [Id]          INT             IDENTITY (1, 1) NOT NULL,
    [Title]       NVARCHAR (50)   NOT NULL,
    [Description] NVARCHAR (2000) NOT NULL,
    [Price]       MONEY           NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[Bookings]...';


GO
ALTER TABLE [dbo].[Bookings]
    ADD DEFAULT 0 FOR [CheckedIn];


GO
PRINT N'Creating Foreign Key [dbo].[FK_Bookings_Rooms]...';


GO
ALTER TABLE [dbo].[Bookings] WITH NOCHECK
    ADD CONSTRAINT [FK_Bookings_Rooms] FOREIGN KEY ([RoomId]) REFERENCES [dbo].[Rooms] ([Id]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Bookings_Guests]...';


GO
ALTER TABLE [dbo].[Bookings] WITH NOCHECK
    ADD CONSTRAINT [FK_Bookings_Guests] FOREIGN KEY ([GuestId]) REFERENCES [dbo].[Guests] ([Id]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Rooms_RoomTypes]...';


GO
ALTER TABLE [dbo].[Rooms] WITH NOCHECK
    ADD CONSTRAINT [FK_Rooms_RoomTypes] FOREIGN KEY ([RoomTypeId]) REFERENCES [dbo].[RoomTypes] ([Id]);


GO
PRINT N'Creating Procedure [dbo].[spBookings_CheckIn]...';


GO
CREATE PROCEDURE [dbo].[spBookings_CheckIn]
	@Id int
AS
begin
	set nocount on;

	update dbo.Bookings
	set CheckedIn = 1
	where Id = @Id;
end
GO
PRINT N'Creating Procedure [dbo].[spBookings_Insert]...';


GO
CREATE PROCEDURE [dbo].[spBookings_Insert]
	@roomId int,
	@guestId int,
	@startDate date,
	@endDate date,
	@totalCost money
AS
begin
	set nocount on;

	insert into dbo.Bookings(RoomId, GuestId, StartDate, EndDate, TotalCost)
	values (@roomId, @guestId, @startDate, @endDate, @totalCost);
end
GO
PRINT N'Creating Procedure [dbo].[spBookings_Search]...';


GO
CREATE PROCEDURE [dbo].[spBookings_Search]
	@lastName nvarchar(50),
	@startDate date
AS
begin
	set nocount on;

	select [b].[Id], [b].[RoomId], [b].[GuestId], [b].[StartDate], [b].[EndDate], 
		[b].[CheckedIn], [b].[TotalCost], [g].[FirstName], [g].[LastName], 
		[r].[RoomNumber], [r].[RoomTypeId], [rt].[Title], [rt].[Description], 
		[rt].[Price]
	from dbo.Bookings b
	inner join dbo.Guests g on b.GuestId = g.Id
	inner join dbo.Rooms r on b.RoomId = r.Id
	inner join dbo.RoomTypes rt on r.RoomTypeId = rt.Id
	where b.StartDate = @startDate and g.LastName = @lastName;
end
GO
PRINT N'Creating Procedure [dbo].[spGuests_Insert]...';


GO
CREATE PROCEDURE [dbo].[spGuests_Insert]
	@firstName nvarchar(50),
	@lastName nvarchar(50)
AS
begin
	set nocount on;

	if not exists (select 1 from dbo.Guests where FirstName = @firstName and LastName = @lastName)
	begin
		insert into dbo.Guests (FirstName, LastName)
		values (@firstName, @lastName);
	end

	select top 1 [Id], [FirstName], [LastName]
	from dbo.Guests
	where FirstName = @firstName and LastName = @lastName;
end
GO
PRINT N'Creating Procedure [dbo].[spRooms_GetAvailableRooms]...';


GO
CREATE PROCEDURE [dbo].[spRooms_GetAvailableRooms]
	@startDate date,
	@endDate date,
	@roomTypeId int
AS
begin
	set nocount on;

	select r.*
	from dbo.Rooms r
	inner join dbo.RoomTypes t on t.Id = r.RoomTypeId
	where r.RoomTypeId = @roomTypeId
	and r.Id not in (
	select b.RoomId
	from dbo.Bookings b
	where (@startDate < b.StartDate and @endDate > b.EndDate)
		or (b.StartDate <= @endDate and @endDate < b.EndDate)
		or (b.StartDate <= @startDate and @startDate < b.EndDate)
	);

end
GO
PRINT N'Creating Procedure [dbo].[spRoomTypes_GetAvailableTypes]...';


GO
CREATE PROCEDURE [dbo].[spRoomTypes_GetAvailableTypes]
	@startDate date,
	@endDate date
AS
begin
	set nocount on;

	select t.Id, t.Title, t.Description, t.Price
	from dbo.Rooms r
	inner join dbo.RoomTypes t on t.Id = r.RoomTypeId
	where r.Id not in (
	select b.RoomId
	from dbo.Bookings b
	where (@startDate < b.StartDate and @endDate > b.EndDate)
		or (b.StartDate <= @endDate and @endDate < b.EndDate)
		or (b.StartDate <= @startDate and @startDate < b.EndDate)
	)
	group by t.Id, t.Title, t.Description, t.Price;
end
GO
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
if not exists (select 1 from dbo.RoomTypes)
begin
    insert into dbo.RoomTypes(Title, Description, Price)
    values ('King Size Bed', 'A room with a king-size bed and a window.', 100),
    ('Two Queen Size Beds', 'A room with two queen-size beds and a window.', 115),
    ('Executive Suite', 'Two rooms, each with a king-size bed and a window.', 205);
end

if not exists (select 1 from dbo.Rooms)
begin
    declare @roomId1 int;
    declare @roomId2 int;
    declare @roomId3 int;

    select @roomId1 = Id from dbo.RoomTypes where Title = 'King Size Bed';
    select @roomId2 = Id from dbo.RoomTypes where Title = 'Two Queen Size Beds';
    select @roomId3 = Id from dbo.RoomTypes where Title = 'Executive Suite';

    insert into dbo.Rooms (RoomNumber, RoomTypeId)
    values ('101', @roomId1),
    ('102', @roomId1),
    ('103', @roomId1),
    ('201', @roomId2),
    ('202', @roomId2),
    ('301', @roomId3);
end
GO

GO
PRINT N'Checking existing data against newly created constraints';


GO
USE [$(DatabaseName)];


GO
ALTER TABLE [dbo].[Bookings] WITH CHECK CHECK CONSTRAINT [FK_Bookings_Rooms];

ALTER TABLE [dbo].[Bookings] WITH CHECK CHECK CONSTRAINT [FK_Bookings_Guests];

ALTER TABLE [dbo].[Rooms] WITH CHECK CHECK CONSTRAINT [FK_Rooms_RoomTypes];


GO
PRINT N'Update complete.';


GO
