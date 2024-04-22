-- TASK 1

CREATE DATABASE [Boardgames]

USE Boardgames
GO

CREATE TABLE Categories (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL)

CREATE TABLE Addresses (
	Id INT PRIMARY KEY IDENTITY,
	StreetName NVARCHAR(100) NOT NULL,
	StreetNumber INT NOT NULL,
	Town VARCHAR(30) NOT NULL,
	Country VARCHAR(50) NOT NULL,
	ZIP INT NOT NULL)

CREATE TABLE Publishers (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(30) UNIQUE NOT NULL,
	AddressId INT FOREIGN KEY REFERENCES Addresses (Id) NOT NULL,
	Website NVARCHAR(40),
	Phone NVARCHAR(20))

CREATE TABLE PlayersRanges (
	Id INT PRIMARY KEY IDENTITY,
	PlayersMin INT NOT NULL,
	PlayersMax INT NOT NULL)

CREATE TABLE Boardgames (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(30) NOT NULL,
	YearPublished INT NOT NULL,
	Rating DECIMAL(4, 2) NOT NULL,
	CategoryId INT FOREIGN KEY REFERENCES Categories (Id) NOT NULL,
	PublisherId	INT FOREIGN KEY REFERENCES Publishers (Id) NOT NULL,
	PlayersRangeId INT FOREIGN KEY REFERENCES PlayersRanges (Id) NOT NULL)

CREATE TABLE Creators (
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(30) NOT NULL,
	LastName NVARCHAR(30) NOT NULL,
	Email NVARCHAR(30) NOT NULL)

CREATE TABLE CreatorsBoardgames (
	CreatorId INT FOREIGN KEY REFERENCES Creators (Id) NOT NULL,
	BoardgameId INT FOREIGN KEY REFERENCES Boardgames (Id) NOT NULL,
	PRIMARY KEY (CreatorId, BoardgameId))

-- TASK 2

INSERT INTO Boardgames ([Name], YearPublished, Rating, CategoryId, PublisherId, PlayersRangeId)
	VALUES
	('Deep Blue', 2019, 5.67, 1, 15, 7),
	('Paris', 2016, 9.78, 7, 1, 5),
	('Catan: Starfarers', 2021, 9.87, 7, 13, 6),
	('Bleeding Kansas', 2020, 3.25, 3, 7, 4),
	('One Small Step', 2019, 5.75, 5, 9, 2)

INSERT INTO Publishers ([Name], AddressId, Website,	Phone)
	VALUES
	('Agman Games', 5, 'www.agmangames.com', '+16546135542'),
	('Amethyst Games', 7, 'www.amethystgames.com', '+15558889992'),
	('BattleBooks', 13, 'www.battlebooks.com', '+12345678907')

-- TASK 3

UPDATE PlayersRanges
SET PlayersMax += 1
WHERE Id = 1

UPDATE Boardgames
SET [Name] = CONCAT([Name], 'V2')
WHERE YearPublished >= 2020

-- TASK 4

DELETE FROM CreatorsBoardgames WHERE BoardgameId IN (1, 16, 31, 47)
DELETE FROM Boardgames WHERE PublisherId IN (1, 16)
DELETE FROM Publishers WHERE AddressId = 5
DELETE FROM Addresses WHERE LEFT(Town, 1) = 'L'

-- TASK 5

SELECT [Name], Rating 
	FROM Boardgames
	ORDER BY YearPublished ASC, [Name] DESC

-- TASK 6

SELECT bg.Id,
bg.[Name],
bg.YearPublished, 
c.[Name] AS CategoryName
FROM Boardgames AS bg
JOIN Categories AS c ON bg.CategoryId = c.Id
WHERE c.[Name] IN ('Strategy Games', 'Wargames')
ORDER BY bg.YearPublished DESC

-- TASK 7

SELECT c.Id,
CONCAT_WS (' ', c.FirstName, c.LastName) AS CreatorName,
c.Email
FROM Creators AS c
LEFT JOIN CreatorsBoardgames AS cb ON c.Id = cb.CreatorId
WHERE cb.BoardgameId IS NULL
GO

-- TASK 8

SELECT TOP (5) b.[Name], b.Rating, c.[Name] AS CategoryName 
FROM Boardgames AS b
	INNER JOIN Categories AS c ON b.CategoryId = c.Id
	INNER JOIN PlayersRanges AS pr ON b.PlayersRangeId = pr.Id
WHERE b.Rating > 7.00 AND b.[Name] LIKE '%a%'
	OR b.Rating > 7.50
	AND pr.PlayersMin = 2 AND pr.PlayersMax = 5
ORDER BY b.[Name] ASC, b.Rating DESC
GO

-- TASK 9

SELECT dt.FullName, dt.Email, dt.Rating
FROM
	(SELECT CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
		c.Email, b.Rating,
		DENSE_RANK() OVER (PARTITION BY c.FirstName ORDER BY b.Rating DESC)
		AS Ranking
	FROM Creators AS c
		INNER JOIN CreatorsBoardgames AS cb ON c.Id = cb.CreatorId
		INNER JOIN Boardgames AS b ON cb.BoardgameId = b.Id
	WHERE c.Email LIKE '%.com') AS dt
WHERE dt.Ranking = 1
GO

WITH GamesRanking
AS
(SELECT CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
		c.Email, b.Rating,
		DENSE_RANK() OVER (PARTITION BY c.FirstName ORDER BY b.Rating DESC)
		AS Ranking
	FROM Creators AS c
		INNER JOIN CreatorsBoardgames AS cb ON c.Id = cb.CreatorId
		INNER JOIN Boardgames AS b ON cb.BoardgameId = b.Id
	WHERE c.Email LIKE '%.com')

SELECT FullName, Email, Rating
FROM GamesRanking
WHERE Ranking = 1

-- TASK 10

SELECT c.LastName,
	CEILING(AVG(b.Rating)),
	p.[Name] AS PublisherName
FROM Creators AS c
	INNER JOIN CreatorsBoardgames AS cb ON c.Id = cb.CreatorId
	INNER JOIN Boardgames AS b ON cb.BoardgameId = b.Id
	INNER JOIN Publishers AS p ON b.PublisherId = p.Id
WHERE p.[Name] = 'Stonemaier Games'
GROUP BY c.LastName, p.[Name]
ORDER BY AVG(b.Rating) DESC
GO

-- TASK 11

CREATE OR ALTER FUNCTION udf_CreatorWithBoardgames(@name NVARCHAR(30))
RETURNS INT
AS
BEGIN
DECLARE @number INT = 
	(SELECT COUNT(cb.BoardgameId)
	FROM Creators AS c
	INNER JOIN CreatorsBoardgames AS cb ON c.Id = cb.CreatorId
	WHERE c.FirstName = @name)
	RETURN @number
END
GO

SELECT dbo.udf_CreatorWithBoardgames('Bruno')
GO

-- TASK 12

CREATE OR ALTER PROCEDURE usp_SearchByCategory
(@category NVARCHAR(50))
AS
BEGIN
	SELECT b.[Name], b.YearPublished, b.Rating, 
	c.[Name] AS CategoryName, 
	p.[Name] AS PublisherName,
	CONCAT(pr.PlayersMin, ' ', 'people') AS MinPlayers,
	CONCAT(pr.PlayersMax, ' ', 'people') AS MaxPlayers
	FROM Boardgames AS b
	JOIN Categories AS c ON b.CategoryId = c.Id
	JOIN Publishers AS p ON b.PublisherId = p.Id
	JOIN PlayersRanges AS pr ON	b.PlayersRangeId = pr.Id
	WHERE c.[Name] = @category
	ORDER BY p.[Name] ASC, b.YearPublished DESC
END
GO

EXEC usp_SearchByCategory 'Wargames'
GO