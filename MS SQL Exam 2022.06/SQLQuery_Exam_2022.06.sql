CREATE DATABASE Zoo
GO

USE Zoo
GO

-- TASK 1

CREATE TABLE Owners (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	PhoneNumber VARCHAR(15) NOT NULL,
	[Address] VARCHAR(50)
);

CREATE TABLE AnimalTypes (
	Id INT PRIMARY KEY IDENTITY,
	AnimalType VARCHAR(30) NOT NULL
);

CREATE TABLE Cages (
	Id INT PRIMARY KEY IDENTITY,
	AnimalTypeId INT FOREIGN KEY REFERENCES AnimalTypes (Id) NOT NULL
);

CREATE TABLE Animals (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(30) NOT NULL,
	BirthDate DATE NOT NULL,
	OwnerId INT FOREIGN KEY REFERENCES Owners (Id),
	AnimalTypeId INT FOREIGN KEY REFERENCES AnimalTypes (Id) NOT NULL
);

CREATE TABLE AnimalsCages (
	CageId INT FOREIGN KEY REFERENCES Cages (Id) NOT NULL,
	AnimalId INT FOREIGN KEY REFERENCES Animals (Id) NOT NULL,
	PRIMARY KEY (CageId, AnimalId)
);

CREATE TABLE VolunteersDepartments (
	Id INT PRIMARY KEY IDENTITY,
	DepartmentName VARCHAR(30) NOT NULL
);

CREATE TABLE Volunteers (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	PhoneNumber VARCHAR(15) NOT NULL,
	[Address] VARCHAR(50),
	AnimalId INT FOREIGN KEY REFERENCES Animals (Id),
	DepartmentId INT FOREIGN KEY REFERENCES VolunteersDepartments (Id) NOT NULL
);

-- TASK 2

INSERT INTO Volunteers ([Name], PhoneNumber, [Address], AnimalId, DepartmentId)
	VALUES
	('Anita Kostova', '0896365412', 'Sofia, 5 Rosa str.', 15, 1),
	('Dimitur Stoev', '0877564223', NULL, 42, 4),
	('Kalina Evtimova', '0896321112', 'Silistra, 21 Breza str.', 9, 7),
	('Stoyan Tomov', '0898564100', 'Montana, 1 Bor str.', 18, 8),
	('Boryana Mileva', '0888112233', NULL, 31, 5)

INSERT INTO Animals ([Name], BirthDate, OwnerId, AnimalTypeId)
	VALUES
	('Giraffe', '2018-09-21', 21, 1),
	('Harpy Eagle', '2015-04-17', 15, 3),
	('Hamadryas Baboon', '2017-11-02', NULL, 1),
	('Tuatara', '2021-06-30', 2, 4)

-- TASK 3

SELECT * FROM Owners
WHERE [Name] = 'Kaloqn Stoqnov'

SELECT * FROM Animals
WHERE OwnerId IS NULL

UPDATE Animals
SET OwnerId = 4
WHERE OwnerId IS NULL

-- TASK 4

DELETE FROM Volunteers
WHERE DepartmentId = 2

DELETE FROM VolunteersDepartments
WHERE DepartmentName = 'Education program assistant'

-- TASK 5

SELECT [Name], PhoneNumber, [Address], AnimalId, DepartmentId
FROM Volunteers
ORDER BY [Name] ASC, AnimalId ASC, DepartmentId ASC

-- TASK 6

SELECT a.[Name],
	ant.AnimalType,
	FORMAT(a.BirthDate,'dd.MM.yyyy') AS BirthDate
FROM Animals AS a
	INNER JOIN AnimalTypes AS ant ON a.AnimalTypeId = ant.Id
ORDER BY a.[Name] ASC

-- TASK 7

SELECT TOP(5)
	o.[Name] AS [Owner],
	COUNT(*) AS CountOfAnimals
FROM Owners AS o
	LEFT JOIN Animals AS a ON o.Id = a.OwnerId
GROUP BY o.[Name]
ORDER BY CountOfAnimals DESC

-- TASK 8

SELECT CONCAT(o.[Name], '-', a.[Name]) AS OwnersAnimals,
	o.PhoneNumber,
	ac.CageId
FROM Owners AS o
	LEFT JOIN Animals AS a ON o.Id = a.OwnerId
	INNER JOIN AnimalsCages AS ac ON a.Id = ac.AnimalId
WHERE a.AnimalTypeId = (
	SELECT Id FROM AnimalTypes
	WHERE AnimalType = 'Mammals')
ORDER BY o.[Name] ASC, a.[Name] DESC

-- TASK 9

SELECT v.[Name], v.PhoneNumber,
	RIGHT (v.[Address], LEN(v.[Address]) - CHARINDEX(',', v.[Address]) - 1)
	AS [Address]
FROM Volunteers AS v
	INNER JOIN VolunteersDepartments AS vd ON v.DepartmentId = vd.Id
WHERE vd.DepartmentName = 'Education program assistant'
	AND v.[Address] LIKE '%Sofia%'
ORDER BY v.[Name] ASC

-- TASK 10

SELECT a.[Name],
	DATEPART(YEAR, a.BirthDate) AS BirthYear,
	ant.AnimalType
FROM Animals AS a
	INNER JOIN AnimalTypes AS ant ON a.AnimalTypeId = ant.Id
WHERE OwnerId IS NULL AND ant.AnimalType <> 'Birds'
	AND DATEDIFF(YEAR, a.BirthDate, '2022-01-01') < 5
ORDER BY a.[Name]
GO

-- TASK 11

CREATE FUNCTION udf_GetVolunteersCountFromADepartment (@VolunteersDepartment VARCHAR(30))
RETURNS INT
AS
BEGIN
	DECLARE @counter INT
	SET @counter = 
	(SELECT COUNT(*) FROM Volunteers AS v
	INNER JOIN VolunteersDepartments AS vd ON v.DepartmentId = vd.Id
	WHERE vd.DepartmentName = @VolunteersDepartment)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
	RETURN @counter
END
GO

SELECT dbo.udf_GetVolunteersCountFromADepartment ('Education program assistant')
SELECT dbo.udf_GetVolunteersCountFromADepartment ('Guest engagement')
SELECT dbo.udf_GetVolunteersCountFromADepartment ('Zoo events')
GO

-- TASK 12

CREATE PROCEDURE usp_AnimalsWithOwnersOrNot 
@AnimalName VARCHAR(30)
AS
BEGIN
	SELECT a.[Name],
		ISNULL(o.[Name], 'For adoption') AS OwnersName
	FROM Animals AS a
		LEFT JOIN Owners AS o ON a.OwnerId = o.Id
	WHERE a.[Name] = @AnimalName
END
GO

EXEC usp_AnimalsWithOwnersOrNot 'Pumpkinseed Sunfish'
EXEC usp_AnimalsWithOwnersOrNot 'Hippo'
EXEC usp_AnimalsWithOwnersOrNot 'Brown bear'