-- TASK 10

SELECT u.Username, AVG(f.Size) AS Size
FROM Users AS u
	LEFT JOIN Commits AS c ON u.Id = c.ContributorId
	LEFT JOIN Files AS f ON c.Id = f.CommitId
GROUP BY u.Username
HAVING AVG(f.Size) IS NOT NULL
ORDER BY AVG(f.Size) DESC, u.Username ASC