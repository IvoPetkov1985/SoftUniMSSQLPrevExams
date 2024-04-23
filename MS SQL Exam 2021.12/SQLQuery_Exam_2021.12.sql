CREATE DATABASE Airport
GO

USE Airport
GO

-- TASK 1

CREATE TABLE Passengers (
	Id INT PRIMARY KEY IDENTITY,
	FullName VARCHAR(100) UNIQUE NOT NULL,
	Email VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Pilots (
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(30) UNIQUE NOT NULL,
	LastName VARCHAR(30) UNIQUE NOT NULL,
	Age TINYINT NOT NULL,
		CHECK (Age BETWEEN 21 AND 62),
	Rating FLOAT,
		CHECK (Rating BETWEEN 0.0 AND 10.0)
);

CREATE TABLE AircraftTypes (
	Id INT PRIMARY KEY IDENTITY,
	TypeName VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE Aircraft (
	Id INT PRIMARY KEY IDENTITY,
	Manufacturer VARCHAR(25) NOT NULL,
	Model VARCHAR(30) NOT NULL,
	[Year] INT NOT NULL,
	FlightHours INT,
	Condition CHAR(1) NOT NULL,
	TypeId INT FOREIGN KEY REFERENCES AircraftTypes (Id) NOT NULL
);

CREATE TABLE PilotsAircraft (
	AircraftId INT FOREIGN KEY REFERENCES Aircraft (Id) NOT NULL,
	PilotId INT FOREIGN KEY REFERENCES Pilots (Id) NOT NULL,
	PRIMARY KEY (AircraftId, PilotId)
);

CREATE TABLE Airports (
	Id INT PRIMARY KEY IDENTITY,
	AirportName VARCHAR(70) UNIQUE NOT NULL,
	Country VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE FlightDestinations (
	Id INT PRIMARY KEY IDENTITY,
	AirportId INT FOREIGN KEY REFERENCES Airports (Id) NOT NULL,
	[Start] DATETIME NOT NULL,
	AircraftId INT FOREIGN KEY REFERENCES Aircraft (Id) NOT NULL,
	PassengerId INT FOREIGN KEY REFERENCES Passengers (Id) NOT NULL,
	TicketPrice DECIMAL(18, 2) DEFAULT 15 NOT NULL
);

-- TASK 5

SELECT Manufacturer, Model, FlightHours, Condition
FROM Aircraft
ORDER BY FlightHours DESC

-- TASK 6

SELECT p.FirstName, p.LastName, 
	a.Manufacturer, a.Model, a.FlightHours
FROM Pilots AS p
	INNER JOIN PilotsAircraft AS pa ON p.Id = pa.PilotId
	INNER JOIN Aircraft AS a ON pa.AircraftId = a.Id
WHERE a.FlightHours IS NOT NULL AND a.FlightHours < 304
ORDER BY a.FlightHours DESC, p.FirstName ASC

-- TASK 7

SELECT TOP (20)
	fd.Id AS DestinationId, fd.[Start],
	p.FullName,
	ap.AirportName,
	fd.TicketPrice
FROM FlightDestinations AS fd
	INNER JOIN Passengers AS p ON fd.PassengerId = p.Id
	INNER JOIN Airports AS ap ON fd.AirportId = ap.Id
WHERE DATEPART(DAY, fd.[Start]) % 2 = 0
ORDER BY fd.TicketPrice DESC, ap.AirportName ASC

-- TASK 8

SELECT a.Id AS AircraftId,
	a.Manufacturer, a.FlightHours,
	COUNT(fd.Id) AS FlightDestinationsCount,
	ROUND(AVG(fd.TicketPrice), 2) AS AvgPrice
FROM Aircraft AS a
	LEFT JOIN FlightDestinations AS fd ON a.Id = fd.AircraftId	
GROUP BY a.Id, a.Manufacturer, a.FlightHours
HAVING COUNT(fd.Id) >= 2
ORDER BY COUNT(fd.Id) DESC, AircraftId ASC

-- TASK 9

SELECT p.FullName,
	COUNT(fd.AircraftId) AS CountOfAircraft,
	SUM(fd.TicketPrice) AS TotalPayed
FROM Passengers AS p
	LEFT JOIN FlightDestinations AS fd ON p.Id = fd.PassengerId
WHERE SUBSTRING(p.FullName, 2, 1) = 'a'
GROUP BY p.FullName
HAVING COUNT(fd.AircraftId) > 1
ORDER BY p.FullName

-- TASK 10

SELECT ap.AirportName, fd.[Start] AS DayTime,
	fd.TicketPrice, p.FullName, ac.Manufacturer, ac.Model
FROM FlightDestinations AS fd
	INNER JOIN Airports AS ap ON fd.AirportId = ap.Id
	INNER JOIN Passengers AS p ON fd.PassengerId = p.Id
	INNER JOIN Aircraft AS ac ON fd.AircraftId = ac.Id
WHERE fd.TicketPrice > 2500
	AND DATEPART(HOUR, fd.[Start]) BETWEEN 6 AND 20
ORDER BY ac.Model ASC
GO

-- TASK 11

CREATE OR ALTER FUNCTION udf_FlightDestinationsByEmail(@email VARCHAR(50))
RETURNS INT
AS
BEGIN
	DECLARE @counter INT;
	SET @counter = 
	(SELECT COUNT(*)
	FROM Passengers AS p
	JOIN FlightDestinations AS fd ON p.Id = fd.PassengerId
	GROUP BY P.Email
	HAVING p.Email = @email)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
RETURN @counter
END
GO

SELECT dbo.udf_FlightDestinationsByEmail ('PierretteDunmuir@gmail.com')
SELECT dbo.udf_FlightDestinationsByEmail('Montacute@gmail.com')
SELECT dbo.udf_FlightDestinationsByEmail('MerisShale@gmail.com')

SELECT Email FROM Passengers
WHERE Email = 'MerisShale@gmail.com'
GO

-- TASK 12

CREATE OR ALTER PROCEDURE usp_SearchByAirportName (@airportName VARCHAR(70))
AS
BEGIN
	SELECT ap.AirportName, p.FullName, 
		CASE
			WHEN fd.TicketPrice <= 400 THEN 'Low'
			WHEN fd.TicketPrice BETWEEN 401 AND 1500 THEN 'Medium'
			WHEN fd.TicketPrice >= 1501 THEN 'High'
		END
		AS LevelOfTickerPrice,
		ac.Manufacturer, ac.Condition, aty.TypeName
	FROM Airports AS ap
		LEFT JOIN FlightDestinations AS fd ON ap.Id = fd.AirportId
		INNER JOIN Passengers AS p ON fd.PassengerId = p.Id
		INNER JOIN Aircraft AS ac ON fd.AircraftId = ac.Id
		INNER JOIN AircraftTypes AS aty ON ac.TypeId = aty.Id
	WHERE ap.AirportName = @airportName
	ORDER BY ac.Manufacturer, p.FullName
END
GO

EXEC usp_SearchByAirportName 'Sir Seretse Khama International Airport'
GO

-- TASK 3

UPDATE Aircraft
SET Condition = 'A'
WHERE Condition IN ('B', 'C')
AND (FlightHours IS NULL OR FlightHours <= 100)
AND [Year] >= 2013

-- TASK 4

DELETE FROM Passengers
WHERE LEN(FullName) <= 10

-- TASK 2

INSERT INTO Passengers (FullName, Email)
SELECT CONCAT (FirstName, ' ', LastName),
	CONCAT (FirstName, LastName, '@gmail.com')
FROM Pilots
WHERE Id BETWEEN 5 AND 15