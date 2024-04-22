CREATE DATABASE TouristAgency2
GO

USE TouristAgency2
GO

-- TASK 1

CREATE TABLE Countries (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(50) NOT NULL
);

CREATE TABLE Destinations (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	CountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL
);

CREATE TABLE Rooms (
	Id INT PRIMARY KEY IDENTITY,
	[Type] VARCHAR(40) NOT NULL,
	Price DECIMAL(18, 2) NOT NULL,
	BedCount INT NOT NULL,
	CONSTRAINT CHK_BedCount CHECK (BedCount BETWEEN 1 AND 10)
);

CREATE TABLE Hotels (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	DestinationId INT FOREIGN KEY REFERENCES Destinations (Id) NOT NULL
);

CREATE TABLE Tourists (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(80) NOT NULL,
	PhoneNumber VARCHAR(20) NOT NULL,
	Email VARCHAR(80),
	CountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL
);

CREATE TABLE Bookings (
	Id INT PRIMARY KEY IDENTITY,
	ArrivalDate DATETIME2 NOT NULL,
	DepartureDate DATETIME2 NOT NULL,
	AdultsCount INT NOT NULL,
	ChildrenCount INT NOT NULL,
	TouristId INT FOREIGN KEY REFERENCES Tourists (Id) NOT NULL,
	HotelId INT FOREIGN KEY REFERENCES Hotels (Id) NOT NULL,
	RoomId INT FOREIGN KEY REFERENCES Rooms (Id) NOT NULL,
	CONSTRAINT CHK_AdultsCount CHECK (AdultsCount BETWEEN 1 AND 10),
	CONSTRAINT CHK_ChildrenCount CHECK (ChildrenCount BETWEEN 0 AND 9)
);

CREATE TABLE HotelsRooms (
	HotelId INT FOREIGN KEY REFERENCES Hotels (Id) NOT NULL,
	RoomId INT FOREIGN KEY REFERENCES Rooms (Id) NOT NULL,
	CONSTRAINT PK_HotelsRooms PRIMARY KEY (HotelId, RoomId)
);

-- TASK 2

INSERT INTO Tourists ([Name], PhoneNumber, Email, CountryId)
	VALUES
	('John Rivers', '653-551-1555', 'john.rivers@example.com', 6),
	('Adeline Aglaé', '122-654-8726', 'adeline.aglae@example.com', 2),
	('Sergio Ramirez', '233-465-2876', 's.ramirez@example.com', 3),
	('Johan Müller', '322-876-9826', 'j.muller@example.com', 7),
	('Eden Smith', '551-874-2234', 'eden.smith@example.com', 6)

INSERT INTO Bookings (ArrivalDate, DepartureDate, AdultsCount, ChildrenCount, TouristId, HotelId, RoomId)
	VALUES
	('2024-03-01', '2024-03-11', 1, 0, 21, 3, 5),
	('2023-12-28', '2024-01-06', 2, 1, 22, 13, 3),
	('2023-11-15', '2023-11-20', 1, 2, 23, 19, 7),
	('2023-12-05', '2023-12-09', 4, 0, 24, 6, 4),
	('2024-05-01', '2024-05-07', 6, 0, 25, 14, 6)

-- TASK 3

UPDATE Bookings
SET DepartureDate = DATEADD(DAY, 1, DepartureDate)
WHERE DATEPART(MONTH, ArrivalDate) = 12
	AND DATEPART(YEAR, ArrivalDate) = 2023

UPDATE Tourists
SET Email = NULL
WHERE [Name] LIKE '%MA%'

-- TASK 4

DELETE FROM Bookings
WHERE TouristId IN (6, 16, 25)

DELETE FROM Tourists
WHERE RIGHT([Name], 5) = 'Smith'

-- TASK 5

SELECT 
	FORMAT(b.ArrivalDate, 'yyyy-MM-dd') AS ArrivalDate,
	b.AdultsCount, b.ChildrenCount
FROM Bookings AS b
	INNER JOIN Rooms AS r ON b.RoomId = r.Id
ORDER BY r.Price DESC, b.ArrivalDate ASC

-- TASK 6

WITH CTE_HotelsBookings (Id, [Name], BookingsCount)
AS
	(SELECT h.Id, h.[Name], COUNT(b.Id) AS Bookings
	FROM Hotels AS h
		INNER JOIN HotelsRooms AS hr ON h.Id = hr.HotelId
		INNER JOIN Rooms AS r ON hr.RoomId = r.Id
		INNER JOIN Bookings AS b ON h.Id = b.HotelId
	WHERE r.[Type] = 'VIP Apartment'
	GROUP BY h.Id, h.[Name])

SELECT Id, [Name] 
FROM CTE_HotelsBookings
ORDER BY BookingsCount DESC

-- TASK 7

SELECT t.Id, t.[Name], t.PhoneNumber
FROM Tourists AS t
	LEFT JOIN Bookings AS b ON t.Id = b.TouristId
WHERE b.HotelId IS NULL
ORDER BY t.[Name] ASC

-- TASK 8

SELECT TOP (10)
	h.[Name] AS HotelName,
	d.[Name] AS DestinationName, 
	c.[Name] AS CountryName
FROM Bookings AS b
	INNER JOIN Hotels AS h ON b.HotelId = h.Id
	INNER JOIN Destinations AS d ON h.DestinationId = d.Id
	INNER JOIN Countries AS c ON d.CountryId = c.Id
WHERE b.ArrivalDate < '2023-12-31'
	AND h.Id % 2 = 1
ORDER BY c.[Name] ASC, b.ArrivalDate ASC

-- TASK 9

SELECT h.[Name] AS HotelName,
	r.Price AS RoomPrice
FROM Tourists AS t
	INNER JOIN Bookings AS b ON t.Id = b.TouristId
	INNER JOIN Hotels AS h ON b.HotelId = h.Id
	INNER JOIN Rooms AS r ON b.RoomId = r.Id
WHERE RIGHT (t.[Name], 2) <> 'EZ'
ORDER BY r.Price DESC

-- TASK 10

SELECT h.[Name] AS HotelName,
SUM(r.Price * DATEDIFF(DAY, b.ArrivalDate, b.DepartureDate)) AS HotelRevenue
FROM Bookings AS b
	INNER JOIN Hotels AS h ON b.HotelId = h.Id
	INNER JOIN Rooms AS r ON b.RoomId = r.Id
GROUP BY h.[Name]
ORDER BY HotelRevenue DESC
GO

-- TASK 11

CREATE FUNCTION udf_RoomsWithTourists(@name VARCHAR(40))
RETURNS INT
AS
BEGIN
DECLARE @counter INT
SET @counter = (
SELECT SUM(b.AdultsCount + b.ChildrenCount) FROM Rooms AS r
	INNER JOIN Bookings AS b ON r.Id = b.RoomId
	WHERE r.[Type] = @name)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
	RETURN @counter
END
GO

SELECT dbo.udf_RoomsWithTourists('Double Room')
GO

-- TASK 12

CREATE PROCEDURE usp_SearchByCountry(@country NVARCHAR(50))
AS
BEGIN
SELECT t.[Name], t.PhoneNumber, t.Email, COUNT(b.Id) AS CountOfBookings
FROM Tourists AS t
	INNER JOIN Countries AS c ON t.CountryId = c.Id
	INNER JOIN Bookings AS b ON t.Id = b.TouristId
WHERE c.[Name] = @country
GROUP BY t.[Name], t.PhoneNumber, t.Email
END
GO

EXEC usp_SearchByCountry 'Greece'
GO