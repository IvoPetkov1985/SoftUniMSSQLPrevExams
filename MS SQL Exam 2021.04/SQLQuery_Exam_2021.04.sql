CREATE DATABASE [Service]
GO

USE [Service]
GO

-- TASK 1

CREATE TABLE Users (
	Id INT PRIMARY KEY IDENTITY,
	Username VARCHAR(30) UNIQUE NOT NULL,
	[Password] VARCHAR(50) NOT NULL,
	[Name] VARCHAR(50),
	Birthdate DATETIME,
	Age INT,
	CHECK (Age BETWEEN 14 AND 110),
	Email VARCHAR(50) NOT NULL
);

CREATE TABLE Departments (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL
);

CREATE TABLE Employees (
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(25),
	LastName VARCHAR(25),
	Birthdate DATETIME,
	Age INT,
	CHECK (Age BETWEEN 18 AND 110),
	DepartmentId INT FOREIGN KEY REFERENCES Departments (Id)
);

CREATE TABLE Categories (
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	DepartmentId INT FOREIGN KEY REFERENCES Departments (Id) NOT NULL
);

CREATE TABLE [Status] (
	Id INT PRIMARY KEY IDENTITY,
	[Label] VARCHAR(20) NOT NULL
);

CREATE TABLE Reports (
	Id INT PRIMARY KEY IDENTITY,
	CategoryId INT FOREIGN KEY REFERENCES Categories (Id) NOT NULL,
	StatusId INT FOREIGN KEY REFERENCES [Status] (Id) NOT NULL,
	OpenDate DATETIME NOT NULL,
	CloseDate DATETIME,
	[Description] VARCHAR(200) NOT NULL,
	UserId INT FOREIGN KEY REFERENCES Users (Id) NOT NULL,
	EmployeeId INT FOREIGN KEY REFERENCES Employees (Id)
);

-- TASK 2

INSERT INTO Employees (FirstName, LastName, Birthdate, DepartmentId)
	VALUES
	('Marlo', 'O''Malley', '1958-9-21', 1),
	('Niki', 'Stanaghan', '1969-11-26', 4),
	('Ayrton', 'Senna', '1960-03-21', 9),
	('Ronnie', 'Peterson', '1944-02-14', 9),
	('Giovanna', 'Amati', '1959-07-20', 5)

INSERT INTO Reports (CategoryId, StatusId, OpenDate, CloseDate, [Description], UserId, EmployeeId)
	VALUES
	(1, 1, '2017-04-13', NULL, 'Stuck Road on Str.133', 6, 2),
	(6, 3, '2015-09-05', '2015-12-06', 'Charity trail running', 3, 5),
	(14, 2, '2015-09-07', NULL, 'Falling bricks on Str.58', 5, 2),
	(4, 3, '2017-07-03', '2017-07-06', 'Cut off streetlight on Str.11', 1, 1)

-- TASK 3

UPDATE Reports
SET CloseDate = CURRENT_TIMESTAMP
WHERE CloseDate IS NULL

-- TASK 4

DELETE FROM Reports
WHERE StatusId = 4

-- TASK 5

SELECT [Description],
FORMAT(OpenDate, 'dd-MM-yyyy')
FROM Reports
WHERE EmployeeId IS NULL
ORDER BY OpenDate ASC, [Description] ASC

-- TASK 6

SELECT r.[Description], 
	c.[Name] AS CategoryName
FROM Reports AS r
	INNER JOIN Categories AS c ON r.CategoryId = c.Id
ORDER BY r.[Description] ASC, c.[Name] ASC

-- TASK 7

SELECT TOP (5)
	c.[Name] AS CategoryName, 
	COUNT(c.Id) AS ReportsNumber
FROM Reports AS r
	INNER JOIN Categories AS c ON r.CategoryId = c.Id
GROUP BY c.[Name]
ORDER BY ReportsNumber DESC

-- TASK 8

SELECT u.Username, c.[Name] AS CategoryName
FROM Reports AS r
	INNER JOIN Users AS u ON r.UserId = u.Id
	INNER JOIN Categories AS c ON r.CategoryId = c.Id
WHERE DATEPART(MONTH, r.OpenDate) = DATEPART(MONTH, u.Birthdate)
	AND DATEPART(DAY, r.OpenDate) = DATEPART(DAY, u.Birthdate)
ORDER BY u.Username ASC, CategoryName ASC

-- TASK 9

SELECT CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
	COUNT(u.Id) AS UsersCount
FROM Employees AS e
	LEFT JOIN Reports AS r ON e.Id = r.EmployeeId
	LEFT JOIN Users AS u ON r.UserId = u.Id
GROUP BY CONCAT(e.FirstName, ' ', e.LastName)
ORDER BY UsersCount DESC, FullName ASC

-- TASK 10

SELECT
	CASE
		WHEN COALESCE(e.FirstName, e.LastName) IS NOT NULL
		THEN CONCAT(e.FirstName, ' ', e.LastName)
		ELSE 'None'
	END AS Employee,
	ISNULL(d.[Name], 'None') AS Department,
	c.[Name] AS Category,
	r.[Description],
	FORMAT(r.OpenDate, 'dd.MM.yyyy') AS OpenDate,
	st.[Label] AS [Status],
	CASE
		WHEN u.[Name] IS NULL THEN 'None'
		ELSE u.[Name]
	END AS [User]
FROM Reports AS r
	LEFT JOIN Employees AS e ON r.EmployeeId = e.Id
	LEFT JOIN Departments AS d ON e.DepartmentId = d.Id
	LEFT JOIN Categories AS c ON r.CategoryId = c.Id
	LEFT JOIN [Status] AS st ON r.StatusId = st.Id
	LEFT JOIN Users AS u ON r.UserId = u.Id
ORDER BY e.FirstName DESC,
	e.LastName DESC,
	Department ASC,
	Category ASC,
	r.[Description] ASC,
	r.OpenDate ASC,
	[Status] ASC,
	[User] ASC
GO

-- TASK 11

CREATE FUNCTION udf_HoursToComplete(@StartDate DATETIME, @EndDate DATETIME)
RETURNS INT
AS
BEGIN
	DECLARE @hoursCount INT
	SET @hoursCount = DATEDIFF(HOUR, @StartDate, @EndDate)
	IF (@hoursCount IS NULL)
		BEGIN
		RETURN 0
		END
	RETURN @hoursCount
END
GO

SELECT dbo.udf_HoursToComplete(OpenDate, CloseDate) AS TotalHours
   FROM Reports
GO

-- TASK 12

CREATE PROC usp_AssignEmployeeToReport(@EmployeeId INT, @ReportId INT)
AS
BEGIN
	   DECLARE @EmployeeDepartmentId INT = (
			   SELECT DepartmentId
			     FROM Employees
				WHERE Id = @EmployeeId)

	   DECLARE @ReportDepartmentId INT = (
			   SELECT c.DepartmentId
			     FROM Reports AS r
				 JOIN Categories AS c ON r.CategoryId = c.Id
				WHERE r.Id = @ReportId)

	   IF(@EmployeeDepartmentId != @ReportDepartmentId)
	   THROW 50001, 'Employee doesn''t belong to the appropriate department!', 1;

	   DECLARE @ReportCategoryId INT = (
			   SELECT r.CategoryId
			     FROM Reports AS r
				 WHERE r.Id = @ReportId)
				  
	   UPDATE Reports
	      SET  EmployeeId = @EmployeeId
END
GO