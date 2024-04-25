CREATE DATABASE ColonialJourney
GO

USE ColonialJourney
GO

-- TASK 1

CREATE TABLE Planets (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(30) NOT NULL
);

CREATE TABLE Spaceports (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	PlanetId INT FOREIGN KEY REFERENCES Planets (Id) NOT NULL
);

CREATE TABLE Spaceships (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	Manufacturer VARCHAR(30) NOT NULL,
	LightSpeedRate INT DEFAULT 0,
		CHECK (LightSpeedRate >= 0)
);

CREATE TABLE Colonists (
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(20) NOT NULL,
	LastName VARCHAR(20) NOT NULL,
	Ucn VARCHAR(10) UNIQUE NOT NULL,
	BirthDate DATE NOT NULL
);

CREATE TABLE Journeys (
	Id INT PRIMARY KEY IDENTITY,
	JourneyStart DATETIME NOT NULL,
	JourneyEnd DATETIME NOT NULL,
	Purpose VARCHAR(11),
		CHECK (Purpose IN ('Medical', 'Technical', 'Educational', 'Military')),
	DestinationSpaceportId INT FOREIGN KEY REFERENCES Spaceports (Id) NOT NULL,
	SpaceshipId INT FOREIGN KEY REFERENCES Spaceships (Id) NOT NULL
);

CREATE TABLE TravelCards (
	Id INT PRIMARY KEY IDENTITY,
	CardNumber CHAR(10) UNIQUE NOT NULL,
	JobDuringJourney VARCHAR(8),
		CHECK (JobDuringJourney IN ('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook')),
	ColonistId INT FOREIGN KEY REFERENCES Colonists (Id) NOT NULL,
	JourneyId INT FOREIGN KEY REFERENCES Journeys (Id) NOT NULL
);

-- TASK 2

INSERT INTO Planets ([Name])
	VALUES
	('Mars'), ('Earth'), ('Jupiter'), ('Saturn')

INSERT INTO Spaceships ([Name], Manufacturer, LightSpeedRate)
	VALUES
	('Golf', 'VW', 3),
	('WakaWaka', 'Wakanda', 4),
	('Falcon9', 'SpaceX', 1),
	('Bed', 'Vidolov', 6)

-- TASK 3

UPDATE Spaceships
SET LightSpeedRate += 1
WHERE Id BETWEEN 8 AND 12

-- TASK 4

DELETE FROM TravelCards
WHERE JourneyId BETWEEN 1 AND 3

DELETE FROM Journeys
WHERE Id BETWEEN 1 AND 3

-- TASK 5

SELECT Id, 
	FORMAT(JourneyStart, 'dd/MM/yyyy') AS JourneyStart,
	FORMAT(JourneyEnd, 'dd/MM/yyyy') AS JourneyEnd
FROM Journeys
WHERE Purpose IN ('Military')
ORDER BY JourneyStart ASC

-- TASK 6

SELECT c.Id,
	CONCAT_WS(' ', c.FirstName, c.LastName) AS full_name
FROM Colonists AS c
	INNER JOIN TravelCards AS tc ON c.Id = tc.ColonistId
WHERE tc.JobDuringJourney IN ('Pilot')
ORDER BY c.Id ASC

-- TASK 7

SELECT COUNT(*) AS [count]
FROM Colonists AS c
	INNER JOIN TravelCards AS tc ON c.Id = tc.ColonistId
	INNER JOIN Journeys AS j ON tc.JourneyId = j.Id
WHERE j.Purpose = 'Technical'

-- TASK 8

SELECT s.[Name], s.Manufacturer
FROM Spaceships AS s
	INNER JOIN Journeys AS j ON j.SpaceshipId = s.Id
	INNER JOIN TravelCards AS tc ON j.Id = tc.JourneyId
	INNER JOIN Colonists AS c ON tc.ColonistId = c.Id
WHERE tc.JobDuringJourney = 'Pilot'
	AND DATEDIFF(YEAR, c.BirthDate, '2019-01-01') < 30
ORDER BY s.[Name] ASC

-- TASK 9

SELECT p.[Name] AS PlanetName,
	COUNT(j.Id) AS JourneysCount
FROM Planets AS p
	LEFT JOIN Spaceports AS sp ON p.Id = sp.PlanetId
	LEFT JOIN Journeys AS j ON sp.Id = j.DestinationSpaceportId
GROUP BY p.[Name]
HAVING COUNT(j.Id) > 0
ORDER BY JourneysCount DESC, p.[Name] ASC

-- TASK 10

SELECT dt.JobDuringJourney, dt.FullName, dt.JobRank FROM
	(SELECT tc.JobDuringJourney,
		CONCAT_WS(' ', c.FirstName, c.LastName) AS FullName,
		DENSE_RANK() OVER (PARTITION BY tc.JobDuringJourney ORDER BY c.BirthDate ASC) AS JobRank
	FROM Colonists AS c
		INNER JOIN TravelCards AS tc ON c.Id = tc.ColonistId) AS dt
WHERE dt.JobRank = 2

WITH cte_TableExpression (JobDuringJourney, FullName, JobRank)
AS (SELECT tc.JobDuringJourney,
		CONCAT_WS(' ', c.FirstName, c.LastName) AS FullName,
		DENSE_RANK() OVER (PARTITION BY tc.JobDuringJourney ORDER BY c.BirthDate ASC) AS JobRank
	FROM Colonists AS c
		INNER JOIN TravelCards AS tc ON c.Id = tc.ColonistId)
SELECT * FROM cte_TableExpression
WHERE JobRank = 2
GO

-- TASK 11

CREATE OR ALTER FUNCTION dbo.udf_GetColonistsCount(@PlanetName VARCHAR (30))
RETURNS INT
AS
BEGIN
DECLARE @counter INT
SET @counter = (
	SELECT COUNT(c.Id)
	FROM Planets AS p
		INNER JOIN Spaceports AS sp ON p.Id = sp.PlanetId
		INNER JOIN Journeys AS j ON sp.Id = j.DestinationSpaceportId
		INNER JOIN TravelCards AS tc ON j.Id = tc.JourneyId
		INNER JOIN Colonists AS c ON tc.ColonistId = c.Id
	WHERE p.[Name] = @PlanetName
	GROUP BY p.Id
	)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
RETURN @counter
END
GO

SELECT dbo.udf_GetColonistsCount('Otroyphus')
GO

-- TASK 12

CREATE OR ALTER PROCEDURE usp_ChangeJourneyPurpose(@JourneyId INT, @NewPurpose VARCHAR(11))
AS
BEGIN
DECLARE @currentJourneyId INT
	SET @currentJourneyId = (SELECT Id FROM Journeys
							WHERE Id = @JourneyId)
		IF (@currentJourneyId IS NULL)
			BEGIN
			;THROW 50001, 'The journey does not exist!', 1
			END

DECLARE @currentPurpose VARCHAR(11)
	SET @currentPurpose = (SELECT Purpose FROM Journeys
							WHERE Id = @JourneyId)
		IF (@currentPurpose = @NewPurpose)
			BEGIN
			;THROW 50002, 'You cannot change the purpose!', 2
			END
	UPDATE Journeys
	SET Purpose = @NewPurpose
	WHERE Id = @JourneyId
END
GO

EXEC usp_ChangeJourneyPurpose 2, 'Educational'
EXEC usp_ChangeJourneyPurpose 196, 'Technical'
EXEC usp_ChangeJourneyPurpose 4, 'Technical'