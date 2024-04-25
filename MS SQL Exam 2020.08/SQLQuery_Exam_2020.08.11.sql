CREATE DATABASE Bakery
GO

USE Bakery
GO

-- TASK 1

CREATE TABLE Countries (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Customers (
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(25) NOT NULL,
	LastName NVARCHAR(25) NOT NULL,
	Gender CHAR(1) NOT NULL,
		CHECK (Gender IN ('M', 'F')),
	Age INT NOT NULL,
	PhoneNumber CHAR(10) NOT NULL,
		CHECK (LEN(PhoneNumber) = 10),
	CountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL
);

CREATE TABLE Products (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(25) UNIQUE NOT NULL,
	[Description] NVARCHAR(250) NOT NULL,
	Recipe NVARCHAR(MAX) NOT NULL,
	Price DECIMAL(6, 2) NOT NULL
);

CREATE TABLE Feedbacks (
	Id INT PRIMARY KEY IDENTITY,
	[Description] NVARCHAR(255),
	Rate DECIMAL(4, 2) NOT NULL,
		CHECK (Rate BETWEEN 0 AND 10),
	ProductId INT FOREIGN KEY REFERENCES Products (Id) NOT NULL,
	CustomerId INT FOREIGN KEY REFERENCES Customers (Id) NOT NULL
);

CREATE TABLE Distributors (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(25) UNIQUE NOT NULL,
	AddressText NVARCHAR(30) NOT NULL,
	Summary NVARCHAR(200) NOT NULL,
	CountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL
);

CREATE TABLE Ingredients (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(30) NOT NULL,
	[Description] NVARCHAR(200) NOT NULL,
	OriginCountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL,
	DistributorId INT FOREIGN KEY REFERENCES Distributors (Id) NOT NULL
);

CREATE TABLE ProductsIngredients (
	ProductId INT FOREIGN KEY REFERENCES Products (Id) NOT NULL,
	IngredientId INT FOREIGN KEY REFERENCES Ingredients (Id) NOT NULL
	PRIMARY KEY (ProductId, IngredientId)
);

-- TASK 2

INSERT INTO Distributors ([Name], CountryId, AddressText, Summary)
	VALUES
	('Deloitte & Touche', 2, '6 Arch St #9757', 'Customizable neutral traveling'),
	('Congress Title', 13, '58 Hancock St', 'Customer loyalty'),
	('Kitchen People', 1, '3 E 31st St #77', 'Triple-buffered stable delivery'),
	('General Color Co Inc', 21, '6185 Bohn St #72', 'Focus group'),
	('Beck Corporation', 23, '21 E 64th Ave', 'Quality-focused 4th generation hardware')

INSERT INTO Customers (FirstName, LastName, Age, Gender, PhoneNumber, CountryId)
	VALUES
	('Francoise', 'Rautenstrauch', 15, 'M', '0195698399', 5),
	('Kendra', 'Loud', 22, 'F', '0063631526', 11),
	('Lourdes', 'Bauswell', 50, 'M', '0139037043', 8),
	('Hannah', 'Edmison', 18, 'F', '0043343686', 1),
	('Tom', 'Loeza', 31, 'M', '0144876096', 23),
	('Queenie', 'Kramarczyk', 30, 'F', '0064215793', 29),
	('Hiu', 'Portaro', 25, 'M', '0068277755', 16),
	('Josefa', 'Opitz', 43, 'F', '0197887645', 17)

-- TASK 3

UPDATE Ingredients
SET DistributorId = 35
WHERE [Name] IN ('Bay Leaf', 'Paprika', 'Poppy')

UPDATE Ingredients
SET OriginCountryId = 14
WHERE OriginCountryId = 8

-- TASK 4

DELETE FROM Feedbacks
WHERE CustomerId = 14 OR ProductId = 5

-- TASK 5

SELECT [Name], Price, [Description]
FROM Products
ORDER BY Price DESC, [Name] ASC

-- TASK 6

SELECT f.ProductId, f.Rate, f.[Description],
	c.Id AS CustomerId, c.Age, c.Gender
FROM Feedbacks AS f
	INNER JOIN Customers AS c ON f.CustomerId = c.Id
WHERE f.Rate < 5.0
ORDER BY f.ProductId DESC, f.Rate ASC

-- TASK 7

SELECT CONCAT_WS(' ', c.FirstName, c.LastName) AS CustomerName,
	c.PhoneNumber, c.Gender
FROM Customers AS c
	LEFT JOIN Feedbacks AS f ON c.Id = f.CustomerId
WHERE f.Id IS NULL
ORDER BY c.Id ASC

-- TASK 8

SELECT cu.FirstName, cu.Age, cu.PhoneNumber
FROM Customers AS cu
	INNER JOIN Countries AS co ON cu.CountryId = co.Id
WHERE (cu.Age >= 21 AND cu.FirstName LIKE '%an%') OR
	(RIGHT(cu.PhoneNumber, 2) = '38' AND co.[Name] <> 'Greece')
ORDER BY cu.FirstName ASC, cu.Age DESC

-- TASK 9

SELECT
	d.[Name] AS DistributorName,
	i.[Name] AS IngredientName,
	p.[Name] AS ProductName,
	AVG(f.Rate) AS AverageRate
FROM Distributors AS d
	INNER JOIN Ingredients AS i ON d.Id = i.DistributorId
	INNER JOIN ProductsIngredients AS pri ON i.Id = pri.IngredientId
	INNER JOIN Products AS p ON pri.ProductId = p.Id
	INNER JOIN Feedbacks AS f ON p.Id = f.ProductId
GROUP BY d.[Name], i.[Name], p.[Name]
HAVING AVG(f.Rate) BETWEEN 5 AND 8
ORDER BY d.[Name] ASC,
	i.[Name] ASC,
	p.[Name] ASC

-- TASK 10

WITH CTE_CountriesDists (CountryName, DisributorName, NumberOfIngredients, RankCount)
AS 
	(SELECT c.[Name] AS CountryName,
		d.[Name] AS DisributorName,
		COUNT(i.Id) AS NumberOfIngredients,
		RANK() OVER (PARTITION BY c.[Name] ORDER BY COUNT(i.Id) DESC) AS RankCount
	FROM Countries AS c
		INNER JOIN Distributors AS d ON c.Id = d.CountryId
		LEFT JOIN Ingredients AS i ON d.Id = i.DistributorId
	GROUP BY c.[Name], d.[Name])

SELECT CountryName, DisributorName 
FROM CTE_CountriesDists
WHERE RankCount = 1
ORDER BY CountryName ASC, DisributorName ASC
GO

-- TASK 11

CREATE VIEW v_UserWithCountries
AS
SELECT CONCAT(cu.FirstName, ' ', cu.LastName) AS CustomerName,
	cu.Age,
	cu.Gender,
	co.[Name] AS CountryName
FROM Customers AS cu
	INNER JOIN Countries AS co ON cu.CountryId = co.Id
GO

SELECT TOP 5 *
FROM v_UserWithCountries
ORDER BY Age
GO

-- TASK 12

CREATE TRIGGER dbo.ProductsToDelete
ON Products
INSTEAD OF DELETE
AS
BEGIN
	DECLARE @deletedProductId INT
	SET @deletedProductId = (SELECT p.Id FROM Products AS p
							JOIN deleted AS d ON p.Id = d.Id)
	DELETE FROM ProductsIngredients
	WHERE ProductId = @deletedProductId
	DELETE FROM Feedbacks
	WHERE ProductId = @deletedProductId
	DELETE FROM Products
	WHERE Id = @deletedProductId
END
GO

DELETE FROM Products
WHERE Id = 7