-- use cases queries
-- for Archer
-- Query 1: Look up personal score history overtime 
EXPLAIN
SELECT * FROM scorerecord 
WHERE ArcherID = 1 
ORDER BY Date DESC;

-- Query 2: Filter records by date range and round type and sorted by highest score or date 
EXPLAIN
SELECT * FROM scorerecord 
WHERE ArcherID = 5
  AND RoundID = 1 
  AND Date BETWEEN '2018-01-01' AND '2025-12-31'
ORDER BY OfficialTotal DESC, Date DESC;

-- Query 3: Look up round definition
EXPLAIN
SELECT r.RoundName, rng.SequenceNo, rng.Distance, rng.Ends, rng.TargetFace
FROM roundinfo r
JOIN rangeinfo rng ON r.RoundID = rng.RoundID
WHERE r.RoundID = 5
ORDER BY rng.SequenceNo ASC;

-- Query 4: Finding rounds that are equivalent to one another 
SELECT b.RoundName AS BaseRound, 
       e.RoundName AS EquivalentRound, 
       c.ClassName, 
       eq.EquipmentName
FROM equivalentround er
JOIN roundinfo b ON er.BaseRoundID = b.RoundID
JOIN roundinfo e ON er.EquivRoundID = e.RoundID
JOIN archerclass c ON er.ClassID = c.ClassID
JOIN equipment eq ON er.EquipmentID = eq.EquipmentID
WHERE b.RoundID = 1;

-- Query 5: Viewing club competition results to see placements and total round scores (doesnt shows)
SELECT a.Fname, a.Lname, s.OfficialTotal
FROM competitionscore cs
JOIN scorerecord s ON cs.RecordID = s.RecordID
JOIN archerinfo a ON s.ArcherID = a.ArcherID
WHERE cs.CompetitionID = 2
ORDER BY s.OfficialTotal DESC;

-- Query 6: Look up championship result of a specific round (doesnt shows anything due to insufficient data)
SELECT a.Fname, a.Lname, s.OfficialTotal
FROM championshipcomp cc
JOIN competition c ON cc.CompetitionID = c.CompetitionID
JOIN competitionscore cs ON c.CompetitionID = cs.CompetitionID
JOIN scorerecord s ON cs.RecordID = s.RecordID
JOIN archerinfo a ON s.ArcherID = a.ArcherID
WHERE cc.ChampionshipID = 1
  AND s.RoundID = 1
ORDER BY s.OfficialTotal DESC;

-- Query 7: Look up personal best score in a specific round
EXPLAIN
SELECT MAX(OfficialTotal) AS PersonalBest 
FROM scorerecord 
WHERE ArcherID = 2 
  AND RoundID = 2 
  AND IsPermanent = TRUE;
  
-- Query 8: Club’s record of best score in a round with archer’s name
EXPLAIN
SELECT a.Fname, a.Lname, s.OfficialTotal
FROM scorerecord s
JOIN archerinfo a ON s.ArcherID = a.ArcherID
WHERE s.RoundID = 1 
  AND s.IsPermanent = TRUE
ORDER BY s.OfficialTotal DESC
LIMIT 1;

-- Club Recorder
-- Query 9: Look up age and gender information to identify archer class
SELECT BirthYear, 
       (YEAR(CURRENT_DATE) - BirthYear) AS CurrentAge, 
       Gender 
FROM archerinfo 
WHERE ArcherID = 1;

-- Query 10: Look up archer’s default equipment to determine their division
SELECT e.EquipmentName 
FROM archerinfo a
JOIN equipment e ON a.DefaultEquipmentID = e.EquipmentID
WHERE a.ArcherID = 1;

-- Query 11: Look up and review archer’s submitted scores
EXPLAIN
SELECT * FROM scorerecord 
WHERE IsPermanent = FALSE;

-- Query 12: Query historical round records (doesnt work bcus no historical round yet i.e. valid from date start at 2020 and no valid to date recorded)
EXPLAIN
SELECT e.RoundName AS HistoricalEquivalent 
FROM equivalentround er
JOIN roundinfo e ON er.EquivRoundID = e.RoundID
WHERE er.BaseRoundID = 1 
  AND '2018-06-15' >= er.ValidFrom 
  AND (er.ValidTo IS NULL OR '2018-06-15' <= er.ValidTo);

-- Query 13: Check if equipment used match with equipment recorded
SELECT s.EquipmentID AS EquipmentUsed, 
       a.DefaultEquipmentID AS ArchersDefaultEquipment
FROM scorerecord s
JOIN archerinfo a ON s.ArcherID = a.ArcherID
WHERE s.RecordID = 9;

-- Query
-- Query
-- Query
-- Query