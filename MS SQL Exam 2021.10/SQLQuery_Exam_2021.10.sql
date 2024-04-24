CREATE DATABASE CigarShop
GO

USE CigarShop
GO

-- TASK 1

CREATE TABLE Sizes (
	Id INT PRIMARY KEY IDENTITY,
	[Length] INT NOT NULL,
	CHECK ([Length] BETWEEN 10 AND 25),
	RingRange DECIMAL(4, 2) NOT NULL,
	CHECK (RingRange BETWEEN 1.5 AND 7.5)
);

CREATE TABLE Tastes (
	Id INT PRIMARY KEY IDENTITY,
	TasteType VARCHAR(20) NOT NULL,
	TasteStrength VARCHAR(15) NOT NULL,
	ImageURL NVARCHAR(100) NOT NULL
);

CREATE TABLE Brands (
	Id INT PRIMARY KEY IDENTITY,
	BrandName VARCHAR(30) UNIQUE NOT NULL,
	BrandDescription VARCHAR(MAX)
);

CREATE TABLE Cigars (
	Id INT PRIMARY KEY IDENTITY,
	CigarName VARCHAR(80) NOT NULL,
	BrandId INT FOREIGN KEY REFERENCES Brands (Id) NOT NULL,
	TastId INT FOREIGN KEY REFERENCES Tastes (Id) NOT NULL,
	SizeId INT FOREIGN KEY REFERENCES Sizes (Id) NOT NULL,
	PriceForSingleCigar MONEY NOT NULL,
	ImageURL NVARCHAR(100) NOT NULL
);

CREATE TABLE Addresses (
	Id INT PRIMARY KEY IDENTITY,
	Town VARCHAR(30) NOT NULL,
	Country NVARCHAR(30) NOT NULL,
	Streat NVARCHAR(100) NOT NULL,
	ZIP VARCHAR(20) NOT NULL
);

CREATE TABLE Clients (
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(30) NOT NULL,
	LastName NVARCHAR(30) NOT NULL,
	Email NVARCHAR(50) NOT NULL,
	AddressId INT FOREIGN KEY REFERENCES Addresses (Id) NOT NULL
);

CREATE TABLE ClientsCigars (
	ClientId INT FOREIGN KEY REFERENCES Clients (Id) NOT NULL,
	CigarId INT FOREIGN KEY REFERENCES Cigars (Id) NOT NULL,
	PRIMARY KEY (ClientId, CigarId)
);

-- TASK 2

INSERT INTO Cigars (CigarName, BrandId, TastId, SizeId, PriceForSingleCigar, ImageURL)
	VALUES
	('COHIBA ROBUSTO', 9, 1, 5, 15.50, 'cohiba-robusto-stick_18.jpg'),
	('COHIBA SIGLO I', 9, 1, 10, 410.00, 'cohiba-siglo-i-stick_12.jpg'),
	('HOYO DE MONTERREY LE HOYO DU MAIRE', 14, 5, 11, 7.50, 'hoyo-du-maire-stick_17.jpg'),
	('HOYO DE MONTERREY LE HOYO DE SAN JUAN', 14, 4, 15, 32.00, 'hoyo-de-san-juan-stick_20.jpg'),
	('TRINIDAD COLONIALES', 2, 3, 8, 85.21, 'trinidad-coloniales-stick_30.jpg')

INSERT INTO Addresses (Town, Country, Streat, ZIP)
	VALUES
	('Sofia', 'Bulgaria', '18 Bul. Vasil levski', '1000'),
	('Athens', 'Greece', '4342 McDonald Avenue', '10435'),
	('Zagreb', 'Croatia', '4333 Lauren Drive', '10000')

-- TASK 3

UPDATE Cigars
SET PriceForSingleCigar *= 1.20
WHERE TastId = (SELECT Id FROM Tastes
WHERE TasteType = 'Spicy')

UPDATE Brands
SET BrandDescription = 'New description'
WHERE BrandDescription IS NULL

-- TASK 4

DELETE FROM Clients
WHERE AddressId IN (7, 8, 10, 23)

DELETE FROM Addresses
WHERE LEFT(Country, 1) = 'C'

-- TASK 5

SELECT CigarName, PriceForSingleCigar, ImageURL
FROM Cigars
ORDER BY PriceForSingleCigar ASC, CigarName DESC

-- TASK 6

SELECT c.Id, c.CigarName, c.PriceForSingleCigar,
	t.TasteType, t.TasteStrength
FROM Cigars AS c
	INNER JOIN Tastes AS t ON c.TastId = t.Id
	AND t.TasteType IN ('Earthy', 'Woody')
ORDER BY c.PriceForSingleCigar DESC

-- TASK 7

SELECT cl.Id,
	CONCAT_WS(' ', cl.FirstName, cl.LastName) AS ClientName,
	cl.Email
FROM Clients AS cl
	LEFT JOIN ClientsCigars AS cc ON cl.Id = cc.ClientId
WHERE cc.CigarId IS NULL
ORDER BY ClientName ASC

-- TASK 8

SELECT TOP (5)
	c.CigarName, c.PriceForSingleCigar, c.ImageURL
FROM Cigars AS c
	INNER JOIN Sizes AS s ON c.SizeId = s.Id
WHERE s.[Length] >= 12 AND (c.CigarName LIKE '%ci%'
	OR c.PriceForSingleCigar > 50) AND s.RingRange > 2.55
ORDER BY c.CigarName ASC, c.PriceForSingleCigar DESC

-- TASK 9

SELECT CONCAT_WS(' ', c.FirstName, c.LastName) AS FullName,
	a.Country, a.ZIP,
	CONCAT('$', MAX(cg.PriceForSingleCigar)) AS CigarPrice
FROM Clients AS c
	INNER JOIN Addresses AS a ON c.AddressId = a.Id
	INNER JOIN ClientsCigars AS cc ON c.Id = cc.ClientId
	INNER JOIN Cigars AS cg ON cc.CigarId = cg.Id
WHERE ISNUMERIC(a.ZIP) = 1
GROUP BY c.FirstName, c.LastName, a.Country, a.ZIP
ORDER BY FullName ASC

-- TASK 10

SELECT c.LastName,
	CEILING(AVG(s.[Length])) AS CiagrLength,
	CEILING(AVG(s.RingRange)) AS CiagrRingRange
FROM Clients AS c
	INNER JOIN ClientsCigars AS cc ON c.Id = cc.ClientId
	INNER JOIN Cigars AS cg ON cc.CigarId = cg.Id
	INNER JOIN Sizes AS s ON cg.SizeId = s.Id
GROUP BY c.LastName
ORDER BY AVG(s.[Length]) DESC
GO

-- TASK 11

CREATE FUNCTION udf_ClientWithCigars(@name NVARCHAR(30))
RETURNS INT
AS
BEGIN
DECLARE @counter INT
SET @counter = 
	(SELECT COUNT (*)
	FROM Clients AS c
	INNER JOIN ClientsCigars AS cc ON c.Id = cc.ClientId
	INNER JOIN Cigars AS cg ON cc.CigarId = cg.Id
	WHERE c.FirstName = @name
	GROUP BY c.FirstName)
	IF (@counter IS NULL)
		BEGIN
		RETURN 0
		END
	RETURN @counter
END
GO

SELECT dbo.udf_ClientWithCigars('Betty')
GO

-- TASK 12

CREATE PROCEDURE usp_SearchByTaste(@taste VARCHAR(20))
AS
BEGIN
SELECT cg.CigarName, 
	CONCAT ('$', cg.PriceForSingleCigar) AS Price,
	t.TasteType, b.BrandName, 
	CONCAT_WS(' ', s.[Length], 'cm') AS CigarLength,
	CONCAT_WS(' ', s.RingRange, 'cm') AS CigarRingRange
FROM Cigars AS cg
	INNER JOIN Tastes AS t ON cg.TastId = t.Id
	INNER JOIN Brands AS b ON cg.BrandId = b.Id
	INNER JOIN Sizes AS s ON cg.SizeId = s.Id
WHERE t.TasteType = @taste
ORDER BY CigarLength ASC, CigarRingRange DESC
END
GO

EXEC usp_SearchByTaste 'Woody'
GO