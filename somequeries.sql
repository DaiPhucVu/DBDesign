-- this file contain multiple queries for testing

-- query 1: check if archer info to equiptment works
SELECT a.Fname, a.Lname, e.EquipmentName
FROM archerinfo a
LEFT JOIN equipment e ON a.DefaultEquipmentID = e.EquipmentID;

-- query 2: show scores according to archer and round
SELECT 
  a.Fname, a.Lname,
  r.RoundName,
  s.PrelimTotal,
  s.OfficialTotal,
  s.IsPermanent
FROM scorerecord s
JOIN archerinfo a ON s.ArcherID = a.ArcherID
JOIN roundinfo r ON s.RoundID = r.RoundID;

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

-- Query 4
SELECT 
  s.RecordID,
  e.EndNo,
  a.ArrowPosition,
  a.ArrowScore,
  a.IsX
FROM scorerecord s
JOIN scorebyend e ON s.RecordID = e.RecordID
JOIN arrowscore a ON e.EndID = a.EndID
WHERE s.RecordID = 1
ORDER BY e.EndNo, a.ArrowPosition;

-- Query 5 calculated total score from arrows
SELECT 
  s.RecordID,
  SUM(a.ArrowScore) AS CalculatedTotal,
  s.PrelimTotal
FROM scorerecord s
JOIN scorebyend e ON s.RecordID = e.RecordID
JOIN arrowscore a ON e.EndID = a.EndID
GROUP BY s.RecordID;

-- Query top archer in a competition
SELECT 
  a.Fname, a.Lname,
  MAX(s.OfficialTotal) AS BestScore
FROM competitionscore cs
JOIN scorerecord s ON cs.RecordID = s.RecordID
JOIN archerinfo a ON s.ArcherID = a.ArcherID
GROUP BY a.ArcherID
ORDER BY BestScore DESC
LIMIT 5;