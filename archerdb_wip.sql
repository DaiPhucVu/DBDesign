-- archery club db
-- built off dai's base, fixed a bunch of stuff

CREATE SCHEMA IF NOT EXISTS `archerdb`;
USE `archerdb`;

-- the 5 bow types the club allows
CREATE TABLE IF NOT EXISTS `equipment` (
  `EquipmentID`   INT NOT NULL AUTO_INCREMENT,
  `EquipmentName` VARCHAR(30) NOT NULL UNIQUE,
  PRIMARY KEY (`EquipmentID`)
);

-- age/gender categories e.g. Male Open, Under 18 Female, 50+ Male etc
CREATE TABLE IF NOT EXISTS `archerclass` (
  `ClassID`   INT NOT NULL AUTO_INCREMENT,
  `ClassName` VARCHAR(50) NOT NULL UNIQUE,
  `Gender`    CHAR(1) NOT NULL,
  `MinAge`    INT,
  `MaxAge`    INT,
  PRIMARY KEY (`ClassID`)
);

-- changed CHAR(10) to VARCHAR(50) bc 10 chars is not enough for a name lol
-- also added AVNumber (archery victoria membership no.) and default equipment
CREATE TABLE IF NOT EXISTS `archerinfo` (
  `ArcherID`           INT NOT NULL AUTO_INCREMENT,
  `AVNumber`           VARCHAR(20) NOT NULL UNIQUE,
  `Fname`              VARCHAR(50) NOT NULL,
  `Lname`              VARCHAR(50) NOT NULL,
  `BirthYear`          YEAR NOT NULL,
  `Gender`             CHAR(1) NOT NULL,
  `DefaultEquipmentID` INT,
  PRIMARY KEY (`ArcherID`),
  FOREIGN KEY (`DefaultEquipmentID`) REFERENCES `equipment`(`EquipmentID`)
);

-- removed Class and Equipment from here, they dont belong in this table
CREATE TABLE IF NOT EXISTS `roundinfo` (
  `RoundID`   INT NOT NULL AUTO_INCREMENT,
  `RoundName` VARCHAR(100) NOT NULL UNIQUE,
  `MaxScore`  INT,
  PRIMARY KEY (`RoundID`)
);

-- fixed: RoundID wasnt actually defined as a column before
-- thats literally why the foreign key wasnt working
-- also Distance and Ends should be numbers not strings
CREATE TABLE IF NOT EXISTS `rangeinfo` (
  `RangeID`    INT NOT NULL AUTO_INCREMENT,
  `RoundID`    INT NOT NULL,
  `SequenceNo` TINYINT NOT NULL,
  `Distance`   INT NOT NULL,
  `Ends`       TINYINT NOT NULL,
  `TargetFace` INT NOT NULL,
  PRIMARY KEY (`RangeID`),
  FOREIGN KEY (`RoundID`) REFERENCES `roundinfo`(`RoundID`)
  ON DELETE CASCADE ON UPDATE CASCADE
);

-- archery australia changes equivalent rounds sometimes so we need to store
-- a history with dates so old competition results dont break
CREATE TABLE IF NOT EXISTS `equivalentround` (
  `EquivID`      INT NOT NULL AUTO_INCREMENT,
  `BaseRoundID`  INT NOT NULL,
  `ClassID`      INT NOT NULL,
  `EquipmentID`  INT NOT NULL,
  `EquivRoundID` INT NOT NULL,
  `ValidFrom`    DATE NOT NULL,
  `ValidTo`      DATE,            -- null just means its still current
  PRIMARY KEY (`EquivID`),
  FOREIGN KEY (`BaseRoundID`)  REFERENCES `roundinfo`(`RoundID`),
  FOREIGN KEY (`ClassID`)      REFERENCES `archerclass`(`ClassID`),
  FOREIGN KEY (`EquipmentID`)  REFERENCES `equipment`(`EquipmentID`),
  FOREIGN KEY (`EquivRoundID`) REFERENCES `roundinfo`(`RoundID`)
);

-- renamed from second rangeinfo (was a naming mistake)
-- added FKs + split total into preliminary (what archer counted) vs official (recorder verified)
-- IsPermanent tracks whether its been approved or still staged on someones phone
CREATE TABLE IF NOT EXISTS `scorerecord` (
  `RecordID`      INT NOT NULL AUTO_INCREMENT,
  `ArcherID`      INT NOT NULL,
  `RoundID`       INT NOT NULL,
  `EquipmentID`   INT NOT NULL,
  `Date`          DATE NOT NULL,
  `Time`          TIME,
  `PrelimTotal`   INT,
  `OfficialTotal` INT,
  `IsPermanent`   BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (`RecordID`),
  FOREIGN KEY (`ArcherID`)    REFERENCES `archerinfo`(`ArcherID`),
  FOREIGN KEY (`RoundID`)     REFERENCES `roundinfo`(`RoundID`),
  FOREIGN KEY (`EquipmentID`) REFERENCES `equipment`(`EquipmentID`)
);

-- each end belongs to a score, RangeNo + EndNo tell you where in the round it sits
CREATE TABLE IF NOT EXISTS `scorebyend` (
  `EndID`    INT NOT NULL AUTO_INCREMENT,
  `RecordID` INT NOT NULL,
  `RangeNo`  TINYINT NOT NULL,
  `EndNo`    TINYINT NOT NULL,
  PRIMARY KEY (`EndID`),
  FOREIGN KEY (`RecordID`) REFERENCES `scorerecord`(`RecordID`)
);

-- renamed from second scorebyend (also a naming mistake)
-- arrows are 0-10, stored highest to lowest bc thats how the rules work
-- IsX is for when someone hits the inner 10 ring (still worth 10 but tracked separately)
CREATE TABLE IF NOT EXISTS `arrowscore` (
  `ArrowID`       INT NOT NULL AUTO_INCREMENT,
  `EndID`         INT NOT NULL,
  `ArrowPosition` TINYINT NOT NULL,
  `ArrowScore`    TINYINT NOT NULL,
  `IsX`           BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (`ArrowID`),
  FOREIGN KEY (`EndID`) REFERENCES `scorebyend`(`EndID`)
);

-- ScoresPerArcher = how many scores count toward this comp (1 = just best, 2 = best + 2nd)
CREATE TABLE IF NOT EXISTS `competition` (
  `CompetitionID`   INT NOT NULL AUTO_INCREMENT,
  `CompetitionName` VARCHAR(100),
  `CompetitionDate` DATE NOT NULL,
  `Venue`           VARCHAR(100),
  `BaseRoundID`     INT NOT NULL,
  `IsChampionship`  BOOLEAN DEFAULT FALSE,
  `ScoresPerArcher` TINYINT DEFAULT 1,
  PRIMARY KEY (`CompetitionID`),
  FOREIGN KEY (`BaseRoundID`) REFERENCES `roundinfo`(`RoundID`)
);

-- links scores to a competition
CREATE TABLE IF NOT EXISTS `competitionscore` (
  `CompetitionID` INT NOT NULL,
  `RecordID`      INT NOT NULL,
  PRIMARY KEY (`CompetitionID`, `RecordID`),
  FOREIGN KEY (`CompetitionID`) REFERENCES `competition`(`CompetitionID`),
  FOREIGN KEY (`RecordID`)      REFERENCES `scorerecord`(`RecordID`)
);

-- yearly championship, basically just a group of competitions
CREATE TABLE IF NOT EXISTS `championship` (
  `ChampionshipID`   INT NOT NULL AUTO_INCREMENT,
  `ChampionshipName` VARCHAR(100),
  `ChampionshipYear` YEAR NOT NULL,
  PRIMARY KEY (`ChampionshipID`)
);

-- which competitions count toward the championship
CREATE TABLE IF NOT EXISTS `championshipcomp` (
  `ChampionshipID` INT NOT NULL,
  `CompetitionID`  INT NOT NULL,
  PRIMARY KEY (`ChampionshipID`, `CompetitionID`),
  FOREIGN KEY (`ChampionshipID`) REFERENCES `championship`(`ChampionshipID`),
  FOREIGN KEY (`CompetitionID`)  REFERENCES `competition`(`CompetitionID`)
);

-- ---- data ----

INSERT INTO `equipment` (`EquipmentName`) VALUES
  ('Recurve'),
  ('Compound'),
  ('Recurve Barebow'),
  ('Compound Barebow'),
  ('Longbow');

INSERT INTO `archerclass` (`ClassName`, `Gender`, `MinAge`, `MaxAge`) VALUES
  ('Male Open',       'M', 21, 49),
  ('Female Open',     'F', 21, 49),
  ('70+ Male',        'M', 70, null),
  ('70+ Female',        'F', 70, null),
  ('60+ Male',        'M', 60, 69),
  ('60+ Female',        'F', 60, 69),
  ('50+ Male',        'M', 50, 59),
  ('50+ Female',      'F', 50, 59),
  ('Under 21 Male',   'M', 18, 20),
  ('Under 21 Female',   'F', 18, 20),
  ('Under 18 Male',   'M', 16, 17),
  ('Under 18 Female', 'F', 16, 17),
  ('Under 16 Male', 'M', 14, 15),
  ('Under 16 Female', 'F', 14, 15),
  ('Under 14 Male', 'M', 6, 13),
  ('Under 14 Female', 'F', 6, 13);

INSERT INTO `archerinfo` (`AVNumber`, `Fname`, `Lname`, `BirthYear`, `Gender`, `DefaultEquipmentID`) VALUES
  ('AV10021', 'James',  'Nguyen',  1995, 'M', 1),  -- recurve, Male Open
  ('AV10034', 'Sarah',  'Okafor',  2001, 'F', 2),  -- compound, Female Open
  ('AV10056', 'Liam',   'Brooks',  2007, 'M', 1),  -- recurve, Under 18 Male
  ('AV10078', 'Maria',  'Flores',  1988, 'F', 1),  -- recurve, Female Open
  ('AV10091', 'Chris',  'Patel',   1990, 'M', 2);  -- compound, Male Open

-- rounds (WA only for now, city rounds still to add)
INSERT INTO `roundinfo` (`RoundName`, `MaxScore`) VALUES
  ('WA90/1440', 1440),
  ('WA70/1440', 1440),
  ('WA60/1440', 1440),
  ('Sydney',    1200);

-- range breakdowns
INSERT INTO `rangeinfo` (`RoundID`, `SequenceNo`, `Distance`, `Ends`, `TargetFace`) VALUES
  (1, 1, 90, 6, 122), (1, 2, 70, 6, 122), (1, 3, 50, 6, 80), (1, 4, 30, 6, 80);  -- WA90/1440
INSERT INTO `rangeinfo` (`RoundID`, `SequenceNo`, `Distance`, `Ends`, `TargetFace`) VALUES
  (2, 1, 70, 6, 122), (2, 2, 60, 6, 122), (2, 3, 50, 6, 80), (2, 4, 30, 6, 80);  -- WA70/1440
INSERT INTO `rangeinfo` (`RoundID`, `SequenceNo`, `Distance`, `Ends`, `TargetFace`) VALUES
  (3, 1, 60, 6, 122), (3, 2, 50, 6, 122), (3, 3, 40, 6, 80), (3, 4, 30, 6, 80);  -- WA60/1440
INSERT INTO `rangeinfo` (`RoundID`, `SequenceNo`, `Distance`, `Ends`, `TargetFace`) VALUES
  (4, 1, 70, 5, 122), (4, 2, 60, 5, 122), (4, 3, 50, 5, 122), (4, 4, 40, 5, 122); -- Sydney

-- equiv rounds
INSERT INTO `equivalentround` (`BaseRoundID`, `ClassID`, `EquipmentID`, `EquivRoundID`, `ValidFrom`, `ValidTo`) VALUES
  (1, 1, 1, 1, '2020-01-01', NULL),   -- Male Open Recurve    -> WA90/1440 (same)
  (1, 1, 2, 1, '2020-01-01', NULL),   -- Male Open Compound   -> WA90/1440 (same)
  (1, 2, 1, 2, '2020-01-01', NULL),   -- Female Open Recurve  -> WA70/1440
  (1, 2, 2, 2, '2020-01-01', NULL),   -- Female Open Compound -> WA70/1440
  (1, 5, 1, 3, '2020-01-01', NULL);   -- Under 18 Male Recurve -> WA60/1440

-- scores: mix of approved and staged
INSERT INTO `scorerecord` (`ArcherID`, `RoundID`, `EquipmentID`, `Date`, `Time`, `PrelimTotal`, `OfficialTotal`, `IsPermanent`) VALUES
  (1, 1, 1, '2025-03-15', '10:30:00', 1134, 1134, TRUE),   -- james, approved
  (2, 2, 2, '2025-03-15', '11:00:00', 1052, 1052, TRUE),   -- sarah, approved
  (4, 2, 1, '2025-03-15', '10:30:00',  987,  987, TRUE),   -- maria, approved
  (5, 1, 2, '2025-03-15', '11:30:00', 1201, 1201, TRUE),   -- chris, approved
  (3, 3, 1, '2025-03-22', '09:00:00',  841, NULL,  FALSE); -- liam, still staged

-- ends for james's score (RecordID 1), range 1 only for now
INSERT INTO `scorebyend` (`RecordID`, `RangeNo`, `EndNo`) VALUES
  (1, 1, 1),
  (1, 1, 2),
  (1, 1, 3),
  (1, 1, 4),
  (1, 1, 5),
  (1, 1, 6);

-- arrows for james's first two ends
INSERT INTO `arrowscore` (`EndID`, `ArrowPosition`, `ArrowScore`, `IsX`) VALUES
  (1, 1, 10, TRUE),  (1, 2, 10, FALSE), (1, 3, 9, FALSE), (1, 4, 9, FALSE), (1, 5, 8, FALSE), (1, 6, 7, FALSE),
  (2, 1, 10, FALSE), (2, 2, 9, FALSE),  (2, 3, 9, FALSE), (2, 4, 8, FALSE), (2, 5, 8, FALSE), (2, 6, 7, FALSE);

-- two competitions
INSERT INTO `competition` (`CompetitionName`, `CompetitionDate`, `Venue`, `BaseRoundID`, `IsChampionship`, `ScoresPerArcher`) VALUES
  ('Club Autumn Classic', '2025-03-15', 'Doncaster Archery Range', 1, FALSE, 1),
  ('State Indoor Champs', '2025-06-20', 'Melbourne Sports Centre',  1, TRUE,  1);

-- link scores to autumn classic
INSERT INTO `competitionscore` (`CompetitionID`, `RecordID`) VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 4);

-- championship
INSERT INTO `championship` (`ChampionshipName`, `ChampionshipYear`) VALUES
  ('Victorian State Championship 2025', 2025);

-- state champs counts toward it
INSERT INTO `championshipcomp` (`ChampionshipID`, `CompetitionID`) VALUES
  (1, 2);
