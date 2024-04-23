CREATE DATABASE NationalTouristSitesOfBulgaria
GO

USE NationalTouristSitesOfBulgaria
GO

-- TASK 1

CREATE TABLE Categories (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL)

CREATE TABLE Locations (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	Municipality VARCHAR(50),
	Province VARCHAR(50))

CREATE TABLE Sites (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(100) NOT NULL,
	LocationId INT FOREIGN KEY REFERENCES Locations (Id) NOT NULL,
	CategoryId INT FOREIGN KEY REFERENCES Categories (Id) NOT NULL,
	Establishment VARCHAR(15))

CREATE TABLE Tourists (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	Age INT NOT NULL,
	CHECK (Age BETWEEN 0 AND 120),
	PhoneNumber VARCHAR(20) NOT NULL,
	Nationality VARCHAR(30) NOT NULL,
	Reward VARCHAR(20))

CREATE TABLE SitesTourists (
	TouristId INT FOREIGN KEY REFERENCES Tourists (Id) NOT NULL,
	SiteId INT FOREIGN KEY REFERENCES Sites (Id) NOT NULL,
	PRIMARY KEY (TouristId, SiteId))

CREATE TABLE BonusPrizes (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL)

CREATE TABLE TouristsBonusPrizes (
	TouristId INT FOREIGN KEY REFERENCES Tourists (Id) NOT NULL,
	BonusPrizeId INT FOREIGN KEY REFERENCES BonusPrizes (Id) NOT NULL,
	PRIMARY KEY (TouristId, BonusPrizeId))

-- TASK 2

INSERT INTO Tourists ([Name], Age, PhoneNumber, Nationality, Reward)
	VALUES
	('Borislava Kazakova', 52, '+359896354244', 'Bulgaria', NULL),
	('Peter Bosh', 48, '+447911844141', 'UK', NULL),
	('Martin Smith', 29, '+353863818592', 'Ireland', 'Bronze badge'),
	('Svilen Dobrev', 49, '+359986584786', 'Bulgaria', 'Silver badge'),
	('Kremena Popova', 38, '+359893298604', 'Bulgaria', NULL)

INSERT INTO Sites ([Name], LocationId, CategoryId, Establishment)
	VALUES
	('Ustra fortress', 90, 7, 'X'),
	('Karlanovo Pyramids', 65, 7, NULL),
	('The Tomb of Tsar Sevt', 63, 8, 'V BC'),
	('Sinite Kamani Natural Park', 17, 1, NULL),
	('St. Petka of Bulgaria – Rupite', 92, 6, '1994')

-- TASK 3

UPDATE Sites
SET Establishment = '(not defined)'
WHERE Establishment IS NULL

-- TASK 4

SELECT * FROM TouristsBonusPrizes

DELETE FROM TouristsBonusPrizes WHERE BonusPrizeId = 5
DELETE FROM BonusPrizes
WHERE [Name] IN ('Sleeping bag')

-- TASK 5

SELECT [Name], Age, PhoneNumber, Nationality 
FROM Tourists
ORDER BY Nationality ASC, Age DESC, [Name] ASC

-- TASK 6

SELECT s.[Name] AS [Site],
	l.[Name] AS [Location],
	s.Establishment,
	c.[Name] AS Category
FROM Sites AS s
	INNER JOIN Locations AS l ON s.LocationId = l.Id
	INNER JOIN Categories AS c ON s.CategoryId = c.Id
ORDER BY Category DESC, [Location] ASC, [Site] ASC

-- TASK 7

SELECT l.Province, l.Municipality, l.[Name] AS [Location],
	COUNT(s.[Name]) AS CountOfSites
FROM Locations AS l
	JOIN Sites AS s ON l.Id = s.LocationId
WHERE l.Province = 'Sofia'
GROUP BY l.Province, l.Municipality, l.[Name]
ORDER BY COUNT(s.[Name]) DESC, l.[Name] ASC

-- TASK 8

SELECT s.[Name] AS [Site],
	l.[Name] AS [Location],
	l.Municipality, l.Province,
	s.Establishment
FROM Sites AS s
	JOIN Locations AS l ON s.LocationId = l.Id
WHERE LEFT(l.[Name], 1) NOT LIKE '[B, M, D]'
	AND s.Establishment LIKE '%BC'
ORDER BY [Site] ASC

-- TASK 9

SELECT t.[Name], t.Age, t.PhoneNumber, t.Nationality, 
	ISNULL(b.[Name], '(no bonus prize)') AS Reward
FROM Tourists AS t
	LEFT JOIN TouristsBonusPrizes AS tb ON t.Id = tb.TouristId
	LEFT JOIN BonusPrizes AS b ON tb.BonusPrizeId = b.Id
ORDER BY t.[Name] ASC

-- TASK 10

SELECT DISTINCT RIGHT(t.[Name], LEN(t.[Name]) - CHARINDEX(' ', t.[Name])) AS LastName,
	t.Nationality, t.Age, t.PhoneNumber
FROM Tourists AS t
	INNER JOIN SitesTourists AS st ON t.Id = st.TouristId
	INNER JOIN Sites AS s ON st.SiteId = s.Id
	INNER JOIN Categories AS c ON s.CategoryId = c.Id
WHERE c.[Name] = 'History and archaeology'
ORDER BY LastName
GO

-- TASK 11

CREATE FUNCTION udf_GetTouristsCountOnATouristSite (@Site VARCHAR(100))
RETURNS INT
AS
BEGIN
DECLARE @counter INT =
	(SELECT COUNT(t.Id)
	FROM Sites AS s
		LEFT JOIN SitesTourists AS st ON s.Id = st.SiteId
		LEFT JOIN Tourists AS t ON st.TouristId = t.Id
	WHERE s.[Name] = @site)
RETURN @counter
END
GO

SELECT dbo.udf_GetTouristsCountOnATouristSite ('Regional History Museum – Vratsa')
SELECT dbo.udf_GetTouristsCountOnATouristSite ('Samuil’s Fortress')
SELECT dbo.udf_GetTouristsCountOnATouristSite ('Gorge of Erma River')
GO

-- TASK 12

CREATE PROCEDURE usp_AnnualRewardLottery(@TouristName VARCHAR(50))
AS
BEGIN
	IF
		(SELECT COUNT(st.SiteId)
		FROM Tourists AS t
		LEFT JOIN SitesTourists AS st ON t.Id = st.TouristId
		WHERE t.[Name] = @TouristName) >= 100
		BEGIN
		UPDATE Tourists
		SET Reward = 'Gold badge'
		WHERE [Name] = @TouristName
		END
	ELSE IF
		(SELECT COUNT(st.SiteId)
		FROM Tourists AS t
		LEFT JOIN SitesTourists AS st ON t.Id = st.TouristId
		WHERE t.[Name] = @TouristName) >= 50
		BEGIN
		UPDATE Tourists
		SET Reward = 'Silver badge'
		WHERE [Name] = @TouristName
		END
	ELSE IF
		(SELECT COUNT(st.SiteId)
		FROM Tourists AS t
		LEFT JOIN SitesTourists AS st ON t.Id = st.TouristId
		WHERE t.[Name] = @TouristName) >= 25
		BEGIN
		UPDATE Tourists
		SET Reward = 'Bronze badge'
		WHERE [Name] = @TouristName
		END

	SELECT [Name], Reward FROM Tourists
	WHERE [Name] = @TouristName
END
GO

EXEC usp_AnnualRewardLottery 'Gerhild Lutgard'
EXEC usp_AnnualRewardLottery 'Teodor Petrov'
EXEC usp_AnnualRewardLottery 'Zac Walsh'
EXEC usp_AnnualRewardLottery 'Brus Brown'