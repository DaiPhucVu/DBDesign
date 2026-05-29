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

-- Indexes --

CREATE INDEX idx_archer_history ON scorerecord(ArcherID, RoundID, Date);

CREATE INDEX idx_round_records ON scorerecord(RoundID, IsPermanent, OfficialTotal);

CREATE INDEX idx_pending_scores ON scorerecord(IsPermanent);

CREATE INDEX idx_range_sequence ON rangeinfo(RoundID, SequenceNo);

CREATE INDEX idx_equiv_dates ON equivalentround(BaseRoundID, ValidFrom, ValidTo);
