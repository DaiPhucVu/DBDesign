-- this file contain multiple queries for testing

-- these queries are for testing
-- query 1: check if archer info to equiptment works
SELECT a.Fname, a.Lname, e.EquipmentName
FROM archerinfo a
LEFT JOIN equipment e ON a.DefaultEquipmentID = e.EquipmentID;

-- query 2: show scores
SELECT 
    a.Fname,
    a.Lname,
    a.AVNumber,
    r.RoundName,
    s.Date,
    s.PrelimTotal,
    s.OfficialTotal
FROM archerinfo a
JOIN scorerecord s ON a.ArcherID = s.ArcherID
JOIN roundinfo r ON s.RoundID = r.RoundID
ORDER BY s.Date DESC, a.Lname ASC;

-- Query 3 for competition results
SELECT 
  c.CompetitionName,
  a.Fname,
  a.Lname,
  s.OfficialTotal
FROM competitionscore cs
JOIN competition c ON cs.CompetitionID = c.CompetitionID
JOIN scorerecord s ON cs.RecordID = s.RecordID
JOIN archerinfo a ON s.ArcherID = a.ArcherID
ORDER BY s.OfficialTotal DESC;

-- Query 4 exact score from a competition
SELECT 
    c.CompetitionName,
    a.Fname,
    a.Lname,
    e.EquipmentName,
    sr.OfficialTotal AS CompetitionScore
FROM competition c
JOIN competitionscore cs ON c.CompetitionID = cs.CompetitionID
JOIN scorerecord sr ON cs.RecordID = sr.RecordID
JOIN archerinfo a ON sr.ArcherID = a.ArcherID
JOIN equipment e ON sr.EquipmentID = e.EquipmentID
WHERE c.CompetitionName = 'Club Spring Open' -- Change to test different competitions
ORDER BY sr.OfficialTotal DESC;

-- Query 5 calculated total score from arrows
SELECT 
    a.Fname, 
    a.Lname, 
    sr.RecordID,
    sr.OfficialTotal AS RecordedTotal,
    SUM(aws.ArrowScore) AS CalculatedTotal,
    COUNT(aws.ArrowID) AS TotalArrowsShot,
    SUM(CASE WHEN aws.IsX = TRUE THEN 1 ELSE 0 END) AS TotalX_Count
FROM archerinfo a
JOIN scorerecord sr ON a.ArcherID = sr.ArcherID
JOIN scorebyend sbe ON sr.RecordID = sbe.RecordID
JOIN arrowscore aws ON sbe.EndID = aws.EndID
GROUP BY a.ArcherID, a.Fname, a.Lname, sr.RecordID, sr.OfficialTotal
ORDER BY CalculatedTotal DESC;

-- Query 6


-- Query 7 catch illegal arrow score
SELECT 
    ArrowID, 
    EndID, 
    ArrowScore, 
    IsX
FROM arrowscore
WHERE ArrowScore < 0 
   OR ArrowScore > 10 
   OR (IsX = TRUE AND ArrowScore != 10);
   
-- Query 8 


-- These are use cases for different scenario

-- Queries for Admin
-- Query 9 looks for score that needs approval
SELECT 
    sr.RecordID,
    a.Fname, 
    a.Lname, 
    r.RoundName, 
    sr.Date, 
    sr.PrelimTotal
FROM scorerecord sr
JOIN archerinfo a ON sr.ArcherID = a.ArcherID
JOIN roundinfo r ON sr.RoundID = r.RoundID
WHERE sr.IsPermanent = FALSE
ORDER BY sr.Date ASC;

-- Query 10 catch unmatched score record
SELECT 
    sr.RecordID, 
    sr.OfficialTotal AS TypedTotal, 
    SUM(aws.ArrowScore) AS TrueCalculatedTotal
FROM scorerecord sr
JOIN scorebyend sbe ON sr.RecordID = sbe.RecordID
JOIN arrowscore aws ON sbe.EndID = aws.EndID
GROUP BY sr.RecordID, sr.OfficialTotal
HAVING sr.OfficialTotal != SUM(aws.ArrowScore)
   OR sr.OfficialTotal IS NULL;

-- Queries for Archer
-- Query 11 Look for personal best
-- All Archer
SELECT 
    a.Fname,
    a.Lname,
    r.RoundName,
    MAX(sr.OfficialTotal) AS PersonalBest,
    COUNT(sr.RecordID) AS TimesShot
FROM archerinfo a
JOIN scorerecord sr ON a.ArcherID = sr.ArcherID
JOIN roundinfo r ON sr.RoundID = r.RoundID
WHERE sr.IsPermanent = TRUE  
GROUP BY a.ArcherID, a.Fname, a.Lname, r.RoundID, r.RoundName
ORDER BY a.Lname ASC, a.Fname ASC, r.RoundName ASC;
-- specific archer
SELECT 
    r.RoundName,
    sr.Date,
    sr.OfficialTotal AS Score
FROM scorerecord sr
JOIN roundinfo r ON sr.RoundID = r.RoundID
WHERE sr.IsPermanent = TRUE 
  AND sr.ArcherID = 15
ORDER BY sr.OfficialTotal DESC
LIMIT 5;

-- Query 12 Calculate for total X and average score
SELECT 
    a.Fname,
    a.Lname,
    SUM(CASE WHEN aws.IsX = TRUE THEN 1 ELSE 0 END) AS TotalXs,
    COUNT(aws.ArrowID) AS TotalArrowsShot,
    ROUND(AVG(aws.ArrowScore), 2) AS AverageArrowScore
FROM archerinfo a
JOIN scorerecord sr ON a.ArcherID = sr.ArcherID
JOIN scorebyend sbe ON sr.RecordID = sbe.RecordID
JOIN arrowscore aws ON sbe.EndID = aws.EndID
WHERE sr.IsPermanent = TRUE  
GROUP BY a.ArcherID, a.Fname, a.Lname
ORDER BY TotalXs DESC, AverageArrowScore DESC;

-- Query 13 Search for score history
SELECT 
    sr.Date,
    r.RoundName,
    e.EquipmentName,
    sr.PrelimTotal AS SubmittedScore,
    sr.OfficialTotal AS VerifiedScore,
    sr.IsPermanent AS IsOfficial
FROM scorerecord sr
JOIN roundinfo r ON sr.RoundID = r.RoundID
JOIN equipment e ON sr.EquipmentID = e.EquipmentID
WHERE sr.ArcherID = 15                  -- Filter by specific Archer: WHERE sr.ArcherID = ?
  AND sr.Date >= '2020-01-01'           -- Filter by Start Date: AND sr.Date >= ?
  AND sr.Date <= '2026-12-31'           -- Filter by End Date AND sr.Date <= ?
  AND r.RoundName = 'WA90/1440'         -- Filter by Round Type AND r.RoundName = ?
ORDER BY sr.Date DESC;