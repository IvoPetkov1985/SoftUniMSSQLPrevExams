CREATE DATABASE Bitbucket
GO

USE Bitbucket
GO

-- TASK 1

CREATE TABLE Users (
	Id INT PRIMARY KEY IDENTITY,
	Username VARCHAR(30) NOT NULL,
	[Password] VARCHAR(30) NOT NULL,
	Email VARCHAR(50) NOT NULL
);

CREATE TABLE Repositories (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL
);

CREATE TABLE RepositoriesContributors (
	RepositoryId INT FOREIGN KEY REFERENCES Repositories (Id) NOT NULL,
	ContributorId INT FOREIGN KEY REFERENCES Users (Id) NOT NULL,
	PRIMARY KEY (RepositoryId, ContributorId)
);

CREATE TABLE Issues (
	Id INT PRIMARY KEY IDENTITY,
	Title VARCHAR(255) NOT NULL,
	IssueStatus VARCHAR(6) NOT NULL,
	RepositoryId INT FOREIGN KEY REFERENCES Repositories (Id) NOT NULL,
	AssigneeId INT FOREIGN KEY REFERENCES Users (Id) NOT NULL
);

CREATE TABLE Commits (
	Id INT PRIMARY KEY IDENTITY,
	[Message] VARCHAR(255) NOT NULL,
	IssueId INT FOREIGN KEY REFERENCES Issues (Id),
	RepositoryId INT FOREIGN KEY REFERENCES Repositories (Id) NOT NULL,
	ContributorId INT FOREIGN KEY REFERENCES Users (Id) NOT NULL
);

CREATE TABLE Files (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(100) NOT NULL,
	Size DECIMAL(18, 2) NOT NULL,
	ParentId INT FOREIGN KEY REFERENCES Files (Id),
	CommitId INT FOREIGN KEY REFERENCES Commits (Id) NOT NULL
);

-- TASK 2

INSERT INTO Files ([Name], Size, ParentId, CommitId)
	VALUES
	('Trade.idk', 2598.0, 1, 1),
	('menu.net', 9238.31, 2, 2),
	('Administrate.soshy', 1246.93, 3, 3),
	('Controller.php', 7353.15, 4, 4),
	('Find.java', 9957.86, 5, 5),
	('Controller.json', 14034.87, 3, 6),
	('Operate.xix', 7662.92, 7, 7)

INSERT INTO Issues (Title, IssueStatus, RepositoryId, AssigneeId)
	VALUES
	('Critical Problem with HomeController.cs file', 'open', 1, 4),
	('Typo fix in Judge.html', 'open', 4, 3),
	('Implement documentation for UsersService.cs', 'closed', 8, 2),
	('Unreachable code in Index.cs', 'open', 9, 8)

-- TASK 3

UPDATE Issues
SET IssueStatus = 'closed'
WHERE AssigneeId = 6

-- TASK 4

DELETE FROM RepositoriesContributors
WHERE RepositoryId = (SELECT Id FROM Repositories
WHERE [Name] = 'Softuni-Teamwork')

DELETE FROM Issues
WHERE RepositoryId = (SELECT Id FROM Repositories
WHERE [Name] = 'Softuni-Teamwork')

DELETE FROM Files
WHERE CommitId = 36

DELETE FROM Commits
WHERE RepositoryId = (SELECT Id FROM Repositories
WHERE [Name] = 'Softuni-Teamwork')

DELETE FROM Repositories
WHERE [Name] = 'Softuni-Teamwork'

-- TASK 5

SELECT Id, [Message], RepositoryId, ContributorId
FROM Commits
ORDER BY Id ASC,
[Message] ASC,
RepositoryId ASC,
ContributorId ASC

-- TASK 6

SELECT Id, [Name], Size
FROM Files
WHERE Size > 1000 AND RIGHT([Name], 4) = 'html'
ORDER BY Size DESC, Id ASC, [Name] ASC

-- TASK 7

SELECT i.Id, 
	CONCAT_WS(' : ', u.Username, i.Title) AS IssueAssignee
FROM Issues AS i
	INNER JOIN Users AS u ON i.AssigneeId = u.Id
ORDER BY i.Id DESC, u.Username ASC

-- TASK 8

SELECT p.Id,
	p.[Name],
	CONCAT (p.Size, 'KB') AS Size
FROM Files AS f
	RIGHT JOIN Files AS p ON f.ParentId = p.Id
WHERE f.Id IS NULL
ORDER BY p.Id ASC, p.[Name] ASC, p.Size DESC

-- TASK 9

SELECT TOP(5) 
	r.Id, r.[Name], COUNT(r.[Name]) AS Commits
FROM Repositories as r
	LEFT JOIN Commits as c ON r.Id = c.RepositoryId
	INNER JOIN RepositoriesContributors AS rc ON rc.RepositoryId = r.Id
GROUP BY r.Id, r.[Name]
ORDER BY Commits DESC, r.Id ASC, r.[Name] ASC
GO

-- TASK 11

CREATE FUNCTION udf_AllUserCommits(@username VARCHAR(30))
RETURNS INT
AS
BEGIN
DECLARE @counter INT
SET @counter = (
	SELECT COUNT(c.Id) FROM Users AS u
	LEFT JOIN Commits AS c ON u.Id = c.ContributorId
	WHERE u.Username = @username
	GROUP BY u.Id)
	IF (@counter IS NULL)
		RETURN 0
	RETURN @counter
END
GO

SELECT dbo.udf_AllUserCommits('UnderSinduxrein')
GO

-- TASK 12

CREATE PROCEDURE usp_SearchForFiles(@fileExtension VARCHAR(7))
AS
BEGIN
	SELECT Id, [Name],
	CONCAT(Size, 'KB') AS Size 
	FROM Files
	WHERE [Name] LIKE CONCAT('%', @fileExtension)
	ORDER BY Id ASC, [Name] ASC, Size DESC
END
GO

EXEC usp_SearchForFiles 'txt'