CREATE DATABASE TripService
GO

USE TripService
GO

-- TASK 1

CREATE TABLE Cities (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(20) NOT NULL,
	CountryCode CHAR(2) NOT NULL
);

CREATE TABLE Hotels (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(50) NOT NULL,
	CityId INT FOREIGN KEY REFERENCES Cities (Id) NOT NULL,
	EmployeeCount INT NOT NULL,
	BaseRate DECIMAL (6, 2)
);

CREATE TABLE Rooms (
	Id INT PRIMARY KEY IDENTITY,
	Price DECIMAL (6, 2) NOT NULL,
	[Type] NVARCHAR(20) NOT NULL,
	Beds INT NOT NULL,
	HotelId INT FOREIGN KEY REFERENCES Hotels (Id) NOT NULL
);

CREATE TABLE Trips (
	Id INT PRIMARY KEY IDENTITY,
	RoomId INT FOREIGN KEY REFERENCES Rooms (Id) NOT NULL,
	BookDate DATE NOT NULL,
	ArrivalDate DATE NOT NULL,
	ReturnDate DATE NOT NULL,
	CancelDate DATE,
	CONSTRAINT CHK_BookDate CHECK (BookDate < ArrivalDate),
	CONSTRAINT CHK_ArrivalDate CHECK (ArrivalDate < ReturnDate)
);

CREATE TABLE Accounts (
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50),
	LastName NVARCHAR(50) NOT NULL,
	CityId INT FOREIGN KEY REFERENCES Cities (Id) NOT NULL,
	BirthDate DATE NOT NULL,
	Email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE AccountsTrips (
	AccountId INT FOREIGN KEY REFERENCES Accounts (Id) NOT NULL,
	TripId INT FOREIGN KEY REFERENCES Trips (Id) NOT NULL,
	Luggage INT NOT NULL,
	CONSTRAINT CHK_Luggage CHECK (Luggage >= 0),
	PRIMARY KEY (AccountId, TripId)
);

-- TASK 2

INSERT INTO Accounts (FirstName, MiddleName, LastName, CityId, BirthDate, Email)
	VALUES
	('John', 'Smith', 'Smith', 34, '1975-07-21', 'j_smith@gmail.com'),
	('Gosho', NULL, 'Petrov', 11, '1978-05-16', 'g_petrov@gmail.com'),
	('Ivan', 'Petrovich', 'Pavlov', 59, '1849-09-26', 'i_pavlov@softuni.bg'),
	('Friedrich', 'Wilhelm', 'Nietzsche', 2, '1844-10-15', 'f_nietzsche@softuni.bg')

INSERT INTO Trips (RoomId, BookDate, ArrivalDate, ReturnDate, CancelDate)
	VALUES
	(101, '2015-04-12', '2015-04-14', '2015-04-20', '2015-02-02'),
	(102, '2015-07-07', '2015-07-15', '2015-07-22', '2015-04-29'),
	(103, '2013-07-17', '2013-07-23', '2013-07-24', NULL),
	(104, '2012-03-17', '2012-03-31', '2012-04-01', '2012-01-10'),
	(109, '2017-08-07', '2017-08-28', '2017-08-29', NULL)

-- TASK 3

UPDATE Rooms
SET Price = Price * 1.14
WHERE HotelId IN (5, 7, 9)

-- TASK 4

DELETE FROM AccountsTrips
WHERE AccountId = 47

-- TASK 5

SELECT 
	a.FirstName, 
	a.LastName, 
	FORMAT(a.BirthDate, 'MM-dd-yyyy') AS BirthDate,
	c.[Name] AS Hometown, 
	a.Email
FROM Accounts AS a
	INNER JOIN Cities AS c ON a.CityId = c.Id
WHERE LEFT (a.Email, 1) IN ('e')
ORDER BY c.[Name] ASC

-- TASK 6

SELECT c.[Name] AS City,
	COUNT(h.Id) AS Hotels
FROM Cities AS c
	RIGHT JOIN Hotels AS h ON c.Id = h.CityId
GROUP BY c.[Name]
HAVING COUNT(h.Id) > 0
ORDER BY Hotels DESC, c.[Name] ASC

-- TASK 7

SELECT a.Id AS AccountId,
	CONCAT_WS(' ', a.FirstName, a.LastName) AS FullName,
	MAX(DATEDIFF(DAY, ArrivalDate, ReturnDate)) AS LongestTrip,
	MIN(DATEDIFF(DAY, ArrivalDate, ReturnDate)) AS ShortestTrip
FROM Accounts AS a
	INNER JOIN AccountsTrips AS atr ON a.Id = atr.AccountId
	INNER JOIN Trips AS tr ON atr.TripId = tr.Id
WHERE a.MiddleName IS NULL AND CancelDate IS NULL
GROUP BY a.Id, a.FirstName, a.LastName
ORDER BY LongestTrip DESC, ShortestTrip ASC

-- TASK 8

SELECT TOP (10)
	c.Id,
	c.[Name],
	c.CountryCode AS Country,
	COUNT(a.Id) AS Accounts
FROM Cities AS c
	INNER JOIN Accounts AS a ON c.Id = a.CityId
GROUP BY c.Id, c.[Name], c.CountryCode
ORDER BY Accounts DESC

-- TASK 9

SELECT a.Id, a.Email, c.[Name] AS City,
	COUNT(tr.Id) AS Trips
FROM Accounts AS a
	INNER JOIN Cities AS c ON a.CityId = c.Id
	INNER JOIN AccountsTrips AS atr ON a.Id = atr.AccountId
	INNER JOIN Trips AS tr ON atr.TripId = tr.Id
	INNER JOIN Rooms AS r ON tr.RoomId = r.Id
	INNER JOIN Hotels AS h ON r.HotelId = h.Id
WHERE h.CityId = a.CityId
GROUP BY a.Id, a.Email, c.[Name]
ORDER BY Trips DESC, a.Id ASC

-- TASK 10

SELECT tr.Id,
	CONCAT_WS(' ', a.FirstName, a.MiddleName, a.LastName) AS [Full Name],
	c.[Name] AS [From],
	ci.[Name] AS [To],
	CASE
		WHEN tr.CancelDate IS NULL THEN CONCAT_WS(' ', DATEDIFF(DAY, tr.ArrivalDate, tr.ReturnDate), 'days')
		ELSE 'Canceled'
	END AS Duration
FROM AccountsTrips AS atr
	INNER JOIN Accounts AS a ON atr.AccountId = a.Id
	INNER JOIN Trips AS tr ON tr.Id = atr.TripId
	INNER JOIN Cities AS c ON a.CityId = c.Id
	INNER JOIN Rooms AS r ON tr.RoomId = r.Id
	INNER JOIN Hotels AS h ON r.HotelId = h.Id
	INNER JOIN Cities AS ci ON h.CityId = ci.Id
ORDER BY [Full Name] ASC, tr.Id ASC
GO

-- “¿—  12

CREATE PROCEDURE usp_SwitchRoom(@TripId INT , @TargetRoomId INT)
AS
BEGIN

	DECLARE @hotelId INT = (
		SELECT h.Id FROM Hotels AS h
		INNER JOIN Rooms AS r ON h.Id = r.HotelId
		INNER JOIN Trips AS t ON r.Id = t.RoomId
		WHERE t.Id = @TripId)

	DECLARE @targetHotelId INT = (
		SELECT h.Id FROM Hotels AS h
		INNER JOIN Rooms AS r ON h.Id = r.HotelId
		WHERE r.Id = @TargetRoomId)

	IF (@hotelId <> @targetHotelId)
		BEGIN
		;THROW 50001, 'Target room is in another hotel!', 1
		END

	DECLARE @peopleCount INT = (
		SELECT COUNT(*) FROM AccountsTrips
		WHERE TripId = @TripId)

	DECLARE @bedsCount INT = (
		SELECT Beds FROM Rooms
		WHERE Id = @TargetRoomId)

	IF (@peopleCount > @bedsCount)
		BEGIN
		;THROW 50002, 'Not enough beds in target room!', 2
		END

	UPDATE Trips
	SET RoomId = @TargetRoomId
	WHERE Id = @TripId

END
GO

EXEC usp_SwitchRoom 10, 7
EXEC usp_SwitchRoom 10, 8