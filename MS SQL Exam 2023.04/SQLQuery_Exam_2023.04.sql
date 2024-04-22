CREATE DATABASE Accounting
GO

USE Accounting
GO

-- TASK 1

CREATE TABLE Countries (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(10) NOT NULL
);

CREATE TABLE Addresses (
	Id INT PRIMARY KEY IDENTITY,
	StreetName NVARCHAR(20) NOT NULL,
	StreetNumber INT,
	PostCode INT NOT NULL,
	City VARCHAR(25) NOT NULL,
	CountryId INT FOREIGN KEY REFERENCES Countries (Id) NOT NULL
);

CREATE TABLE Vendors (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(25) NOT NULL,
	NumberVAT NVARCHAR(15) NOT NULL,
	AddressId INT FOREIGN KEY REFERENCES Addresses (Id) NOT NULL
);

CREATE TABLE Clients (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(25) NOT NULL,
	NumberVAT NVARCHAR(15) NOT NULL,
	AddressId INT FOREIGN KEY REFERENCES Addresses (Id) NOT NULL
);

CREATE TABLE Categories (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(10) NOT NULL
);

CREATE TABLE Products (
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(35) NOT NULL,
	Price DECIMAL(18, 2) NOT NULL,
	CategoryId INT FOREIGN KEY REFERENCES Categories (Id) NOT NULL,
	VendorId INT FOREIGN KEY REFERENCES Vendors (Id) NOT NULL
);

CREATE TABLE Invoices (
	Id INT PRIMARY KEY IDENTITY,
	Number INT UNIQUE NOT NULL,
	IssueDate DATETIME2 NOT NULL,
	DueDate DATETIME2 NOT NULL,
	Amount DECIMAL(18, 2) NOT NULL,
	Currency VARCHAR(5) NOT NULL,
	ClientId INT FOREIGN KEY REFERENCES Clients (Id) NOT NULL
);

CREATE TABLE ProductsClients (
	ProductId INT FOREIGN KEY REFERENCES Products (Id) NOT NULL,
	ClientId INT FOREIGN KEY REFERENCES Clients (Id) NOT NULL,
	PRIMARY KEY (ProductId, ClientId)
);

-- TASK 2

INSERT INTO Products ([Name], Price, CategoryId, VendorId)
	VALUES
	('SCANIA Oil Filter XD01', 78.69, 1, 1),
	('MAN Air Filter XD01', 97.38, 1, 5),
	('DAF Light Bulb 05FG87', 55.00, 2, 13),
	('ADR Shoes 47-47.5', 49.85, 3, 5),
	('Anti-slip pads S', 5.87, 5, 7)

INSERT INTO Invoices (Number, IssueDate, DueDate, Amount, Currency, ClientId)
	VALUES
	(1219992181, '2023-03-01', '2023-04-30', 180.96, 'BGN', 3),
	(1729252340, '2022-11-06', '2023-01-04', 158.18, 'EUR', 13),
	(1950101013, '2023-02-17', '2023-04-18', 615.15, 'USD', 19)

-- TASK 3

UPDATE Invoices
SET DueDate = '2023-04-01'
WHERE IssueDate BETWEEN '2022-11-01' AND '2022-11-30'

UPDATE Clients
SET AddressId = 3
WHERE [Name] LIKE '%CO%'

-- TASK 4

DELETE FROM ProductsClients
WHERE ClientId = 11

DELETE FROM Invoices
WHERE Id IN (11, 30)

DELETE FROM Clients
WHERE LEFT(NumberVAT, 2) = 'IT'

-- TASK 5

SELECT Number, Currency
FROM Invoices
ORDER BY Amount DESC, DueDate ASC

-- TASK 6

SELECT p.Id, p.[Name], p.Price,
	c.[Name] AS CategoryName
FROM Products AS p
	INNER JOIN Categories AS c ON p.CategoryId = c.Id
WHERE c.[Name] IN ('ADR', 'Others')
ORDER BY p.Price DESC

-- TASK 7

SELECT c.Id,
	c.[Name] AS Client,
	CONCAT(a.StreetName, ' ', a.StreetNumber, ', ', a.City, ', ', a.PostCode, ', ', ctr.[Name])
	AS [Address]
FROM Clients AS c
	INNER JOIN Addresses AS a ON c.AddressId = a.Id
	INNER JOIN Countries AS ctr ON a.CountryId = ctr.Id
	LEFT JOIN ProductsClients AS pc ON c.Id = pc.ClientId
WHERE pc.ProductId IS NULL
ORDER BY c.[Name] ASC

-- TASK 8

SELECT TOP (7)
	i.Number, i.Amount,
	c.[Name] AS Client
FROM Invoices AS i
	JOIN Clients AS c ON i.ClientId = c.Id
WHERE (i.IssueDate < '2023-01-01' AND i.Currency = 'EUR')
	OR (i.Amount > 500.00 AND LEFT(c.NumberVAT, 2) = 'DE')
ORDER BY i.Number ASC, i.Amount DESC

-- TASK 9

SELECT c.[Name] AS Client,
	MAX(p.Price) AS Price,
	c.NumberVAT AS [VAT Number]
FROM Clients AS c
	JOIN ProductsClients AS pc ON c.Id = pc.ClientId
	JOIN Products AS p ON pc.ProductId = p.Id
WHERE RIGHT (c.[Name], 2) <> 'KG'
GROUP BY c.[Name], c.NumberVAT
ORDER BY MAX(p.Price) DESC

-- TASK 10

SELECT c.[Name] AS Client,
	FLOOR(AVG(p.Price)) AS [Average Price]
FROM Clients AS c
	INNER JOIN ProductsClients AS pc ON c.Id = pc.ClientId
	INNER JOIN Products AS p ON pc.ProductId = p.Id
	INNER JOIN Vendors AS v ON p.VendorId = v.Id
WHERE v.NumberVAT LIKE '%FR%'
GROUP BY c.[Name]
ORDER BY AVG(p.Price) ASC, c.[Name] DESC
GO

-- TASK 11

CREATE OR ALTER FUNCTION udf_ProductWithClients(@name NVARCHAR(35))
RETURNS INT
AS
BEGIN
	DECLARE @counter INT
	SET @counter = 
	(SELECT COUNT(*) 
	FROM Clients AS c
		INNER JOIN ProductsClients AS pc ON c.Id = pc.ClientId
		INNER JOIN Products AS p ON pc.ProductId = p.Id
	WHERE p.[Name] = @name)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
RETURN @counter
END
GO

SELECT dbo.udf_ProductWithClients('DAF FILTER HU12103X')
GO

-- TASK 12

CREATE PROCEDURE usp_SearchByCountry(@country VARCHAR(10))
AS
BEGIN
	SELECT v.[Name] AS Vendor,
		v.NumberVAT AS VAT,
		CONCAT_WS(' ', a.StreetName, a.StreetNumber) AS [Street Info],
		CONCAT_WS(' ', a.City, a.PostCode) AS [City Info]
	FROM Vendors AS v
		INNER JOIN Addresses AS a ON v.AddressId = a.Id
		INNER JOIN Countries AS c ON a.CountryId = c.Id
	WHERE c.[Name] = @country
END
GO

EXEC usp_SearchByCountry 'France'