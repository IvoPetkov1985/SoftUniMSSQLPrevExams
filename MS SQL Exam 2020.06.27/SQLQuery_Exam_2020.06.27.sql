CREATE DATABASE WMS
GO

USE WMS
GO

-- TASK 1

CREATE TABLE Clients (
	ClientId INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Phone CHAR(12) NOT NULL
);

CREATE TABLE Mechanics (
	MechanicId INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	[Address] VARCHAR(255) NOT NULL
);

CREATE TABLE Models (
	ModelId INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Jobs (
	JobId INT PRIMARY KEY IDENTITY,
	ModelId INT FOREIGN KEY REFERENCES Models (ModelId) NOT NULL,
	[Status] VARCHAR(11) NOT NULL DEFAULT 'Pending',
		CHECK ([Status] IN ('Pending', 'In Progress', 'Finished')),
	ClientId INT FOREIGN KEY REFERENCES Clients (ClientId) NOT NULL,
	MechanicId INT FOREIGN KEY REFERENCES Mechanics (MechanicId),
	IssueDate DATE NOT NULL,
	FinishDate DATE
);

CREATE TABLE Orders (
	OrderId INT PRIMARY KEY IDENTITY,
	JobId INT FOREIGN KEY REFERENCES Jobs (JobId) NOT NULL,
	IssueDate DATE,
	Delivered BIT DEFAULT 0 NOT NULL
);

CREATE TABLE Vendors (
	VendorId INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Parts (
	PartId INT PRIMARY KEY IDENTITY,
	SerialNumber VARCHAR(50) UNIQUE NOT NULL,
	[Description] VARCHAR(255),
	Price MONEY NOT NULL,
		CHECK (Price > 0 AND Price <= 9999.99),
	VendorId INT FOREIGN KEY REFERENCES Vendors NOT NULL,
	StockQty INT DEFAULT 0 NOT NULL,
		CHECK (StockQty >= 0)
);

CREATE TABLE OrderParts (
	OrderId INT FOREIGN KEY REFERENCES Orders (OrderId) NOT NULL,
	PartId INT FOREIGN KEY REFERENCES Parts (PartId) NOT NULL,
	Quantity INT DEFAULT 1 NOT NULL,
		CHECK (Quantity > 0),
	PRIMARY KEY (OrderId, PartId)
);

CREATE TABLE PartsNeeded (
	JobId INT FOREIGN KEY REFERENCES Jobs (JobId) NOT NULL,
	PartId INT FOREIGN KEY REFERENCES Parts (PartId) NOT NULL,
	Quantity INT DEFAULT 1 NOT NULL,
		CHECK (Quantity > 0),
	PRIMARY KEY (JobId, PartId)
);

-- TASK 2

INSERT INTO Clients (FirstName, LastName, Phone)
	VALUES
	('Teri', 'Ennaco', '570-889-5187'),
	('Merlyn', 'Lawler', '201-588-7810'),
	('Georgene', 'Montezuma', '925-615-5185'),
	('Jettie', 'Mconnell', '908-802-3564'),
	('Lemuel', 'Latzke', '631-748-6479'),
	('Melodie', 'Knipp', '805-690-1682'),
	('Candida', 'Corbley', '908-275-8357');

INSERT INTO Parts (SerialNumber, [Description], Price, VendorId)
	VALUES
	('WP8182119', 'Door Boot Seal', 117.86, 2),
	('W10780048', 'Suspension Rod', 42.81, 1),
	('W10841140', 'Silicone Adhesive', 6.77, 4),
	('WPY055980', 'High Temperature Adhesive', 13.94, 3)

-- TASK 3

UPDATE Jobs
SET MechanicId = 3
WHERE [Status] = 'Pending'

UPDATE Jobs
SET [Status] = 'In Progress'
WHERE [Status] = 'Pending'

-- TASK 4

DELETE FROM OrderParts
WHERE OrderId = 19

DELETE FROM Orders
WHERE OrderId = 19

-- TASK 5

SELECT CONCAT(m.FirstName, ' ', m.LastName) AS Mechanic,
	j.[Status], j.IssueDate
FROM Mechanics AS m
	INNER JOIN Jobs AS j ON m.MechanicId = j.MechanicId
ORDER BY m.MechanicId ASC, j.IssueDate ASC, j.JobId ASC

-- TASK 6

SELECT CONCAT_WS(' ', c.FirstName, c.LastName) AS Client,
	DATEDIFF(DAY, j.IssueDate, '2017-04-24') AS [Days going],
	j.[Status]
FROM Clients AS c
	INNER JOIN Jobs AS j ON c.ClientId = j.JobId
WHERE j.[Status] <> 'Finished'
ORDER BY [Days going] DESC, c.ClientId ASC

-- TASK 7

SELECT
	CONCAT_WS(' ', m.FirstName, m.LastName) AS Mechanic,
	AVG(DATEDIFF(DAY, j.IssueDate, j.FinishDate)) AS [Average Days]
FROM Mechanics AS m
	LEFT JOIN Jobs AS j ON m.MechanicId = j.MechanicId
WHERE j.[Status] = 'Finished'
GROUP BY m.MechanicId, m.FirstName, m.LastName

-- TASK 8

SELECT CONCAT_WS(' ', m.FirstName, m.LastName) AS Available
FROM Mechanics AS m
	LEFT JOIN Jobs AS j ON m.MechanicId = j.MechanicId
WHERE j.[Status] IN ('Finished') OR j.[Status] IS NULL
GROUP BY m.MechanicId, FirstName, m.LastName

-- TASK 9

SELECT j.JobId, SUM(pn.Quantity * p.Price) AS Total
FROM Jobs AS j
	LEFT JOIN PartsNeeded AS pn ON j.JobId = pn.JobId
	LEFT JOIN Parts AS p ON pn.PartId = p.PartId
WHERE j.[Status] = 'Finished'
GROUP BY j.JobId
ORDER BY Total DESC, j.JobId ASC

-- 7/7
SELECT j.JobId, ISNULL(SUM(op.Quantity * p.Price), 0) AS Total
FROM Jobs AS j
	LEFT JOIN Orders AS o ON j.JobId = o.JobId
	LEFT JOIN OrderParts AS op ON o.OrderId = op.OrderId
	LEFT JOIN Parts AS p ON op.PartId = p.PartId
WHERE j.[Status] = 'Finished'
GROUP BY j.JobId
ORDER BY Total DESC, j.JobId ASC