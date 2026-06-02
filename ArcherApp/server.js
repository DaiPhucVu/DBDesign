import express from 'express'
import cors from 'cors'
import mysql from 'mysql2/promise'

const isValidInteger = (value) => {
  return Number.isInteger(Number(value)) && Number(value) > 0
}

const isValidDate = (value) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(value)
}

const isValidTime = (value) => {
  return /^\d{2}:\d{2}(:\d{2})?$/.test(value)
}

const app = express()
const port = process.env.PORT || 3000
const dbName = process.env.DB_DATABASE || 'archerdb'
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || ''
}

const ensureDatabase = async () => {
  const connection = await mysql.createConnection(dbConfig)
  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`)
  await connection.end()
}

const pool = mysql.createPool({
  ...dbConfig,
  database: dbName,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
})

const ensureTables = async () => {
  // Ensure the core tables used by the app exist (safe if already created by archerdb_wip.sql)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS equipment (
      EquipmentID INT NOT NULL AUTO_INCREMENT,
      EquipmentName VARCHAR(30) NOT NULL UNIQUE,
      PRIMARY KEY (EquipmentID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS archerinfo (
      ArcherID INT NOT NULL AUTO_INCREMENT,
      AVNumber VARCHAR(20) NOT NULL UNIQUE,
      Fname VARCHAR(50) NOT NULL,
      Lname VARCHAR(50) NOT NULL,
      BirthYear YEAR NOT NULL,
      Gender CHAR(1) NOT NULL,
      DefaultEquipmentID INT,
      PRIMARY KEY (ArcherID),
      FOREIGN KEY (DefaultEquipmentID) REFERENCES equipment(EquipmentID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS roundinfo (
      RoundID INT NOT NULL AUTO_INCREMENT,
      RoundName VARCHAR(100) NOT NULL UNIQUE,
      MaxScore INT,
      PRIMARY KEY (RoundID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS rangeinfo (
      RangeID INT NOT NULL AUTO_INCREMENT,
      RoundID INT NOT NULL,
      SequenceNo TINYINT NOT NULL,
      Distance INT NOT NULL,
      Ends TINYINT NOT NULL,
      TargetFace INT NOT NULL,
      PRIMARY KEY (RangeID),
      FOREIGN KEY (RoundID) REFERENCES roundinfo(RoundID) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS scorerecord (
      RecordID INT NOT NULL AUTO_INCREMENT,
      ArcherID INT NOT NULL,
      RoundID INT NOT NULL,
      EquipmentID INT NOT NULL,
      Date DATE NOT NULL,
      Time TIME,
      PrelimTotal INT,
      OfficialTotal INT,
      IsPermanent BOOLEAN DEFAULT FALSE,
      PRIMARY KEY (RecordID),
      FOREIGN KEY (ArcherID) REFERENCES archerinfo(ArcherID),
      FOREIGN KEY (RoundID) REFERENCES roundinfo(RoundID),
      FOREIGN KEY (EquipmentID) REFERENCES equipment(EquipmentID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS scorebyend (
      EndID INT NOT NULL AUTO_INCREMENT,
      RecordID INT NOT NULL,
      RangeNo TINYINT NOT NULL,
      EndNo TINYINT NOT NULL,
      PRIMARY KEY (EndID),
      FOREIGN KEY (RecordID) REFERENCES scorerecord(RecordID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)

  await pool.query(`
    CREATE TABLE IF NOT EXISTS arrowscore (
      ArrowID INT NOT NULL AUTO_INCREMENT,
      EndID INT NOT NULL,
      ArrowPosition TINYINT NOT NULL,
      ArrowScore TINYINT NOT NULL,
      IsX BOOLEAN DEFAULT FALSE,
      PRIMARY KEY (ArrowID),
      FOREIGN KEY (EndID) REFERENCES scorebyend(EndID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `)
}

app.use(cors())
app.use(express.json())

// Return available rounds with total ends
app.get('/api/rounds', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT r.RoundID, r.RoundName, COALESCE(SUM(ri.Ends),0) AS TotalEnds
       FROM roundinfo r
       LEFT JOIN rangeinfo ri ON ri.RoundID = r.RoundID
       GROUP BY r.RoundID, r.RoundName`
    )
    res.json(rows)
  } catch (err) {
    console.error('GET /api/rounds', err)
    res.status(500).json({ error: 'Unable to fetch rounds' })
  }
})

// List archers
app.get('/api/archers', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT ArcherID, AVNumber, Fname, Lname, DefaultEquipmentID FROM archerinfo ORDER BY Lname, Fname')
    res.json(rows)
  } catch (err) {
    console.error('GET /api/archers', err)
    res.status(500).json({ error: 'Unable to fetch archers' })
  }
})

// List equipment
app.get('/api/equipment', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT EquipmentID, EquipmentName FROM equipment')
    res.json(rows)
  } catch (err) {
    console.error('GET /api/equipment', err)
    res.status(500).json({ error: 'Unable to fetch equipment' })
  }
})

// Create a new scorerecord (start entry session)
app.post('/api/records', async (req, res) => {
  const { ArcherID, RoundID, EquipmentID, EntryDate, Time } = req.body

if (
  !isValidInteger(ArcherID) ||
  !isValidInteger(RoundID) ||
  !isValidInteger(EquipmentID)
) {
  return res.status(400).json({
    error: 'Invalid ArcherID, RoundID or EquipmentID'
  })
}

if (EntryDate && !isValidDate(EntryDate)) {
  return res.status(400).json({
    error: 'Invalid date format'
  })
}

if (Time && !isValidTime(Time)) {
  return res.status(400).json({
    error: 'Invalid time format'
  })
}

  try {
    const recordDate = EntryDate || new Date().toISOString().slice(0, 10)
    const recordTime = new Date().toTimeString().split(' ')[0] // Time parameter has no use in this func as script gets system time.
    const [result] = await pool.query(
      'INSERT INTO scorerecord (ArcherID, RoundID, EquipmentID, Date, Time, PrelimTotal, IsPermanent) VALUES (?, ?, ?, ?, ?, 0, false)',
      [ArcherID, RoundID, EquipmentID, recordDate, recordTime || null]
    )
    res.status(201).json({ RecordID: result.insertId })
  } catch (err) {
    console.error('POST /api/records', err)
    res.status(500).json({ error: 'Unable to create record' })
  }
})

// Add an end and its arrows for a record
app.post('/api/records/:id/ends', async (req, res) => {
  const recordId = Number(req.params.id)
const { RangeNo, EndNo, Arrows } = req.body

if (!isValidInteger(recordId)) {
  return res.status(400).json({
    error: 'Invalid RecordID'
  })
}

if (!isValidInteger(RangeNo)) {
  return res.status(400).json({
    error: 'Invalid RangeNo'
  })
}

if (!isValidInteger(EndNo)) {
  return res.status(400).json({
    error: 'Invalid EndNo'
  })
}

if (!Array.isArray(Arrows) || Arrows.length === 0) {
  return res.status(400).json({
    error: 'Arrows are required'
  })
} // Arrows = [{position:1,score:10,isX:true},...]
  if (!recordId || !Array.isArray(Arrows) || Arrows.length === 0) return res.status(400).json({ error: 'Missing data' })

  try {
    const [endResult] = await pool.query('INSERT INTO scorebyend (RecordID, RangeNo, EndNo) VALUES (?, ?, ?)', [recordId, RangeNo || 1, EndNo || 1])
    const endId = endResult.insertId

    const insertArrow = 'INSERT INTO arrowscore (EndID, ArrowPosition, ArrowScore, IsX) VALUES (?, ?, ?, ?)'
    let sum = 0
    for (const a of Arrows) {
  const pos = Number(a.position)
  const score = a.score === 'M' ? 0 : Number(a.score)
  const isX = !!a.isX

  if (!Number.isInteger(pos) || pos < 1 || pos > 6) {
    return res.status(400).json({
      error: 'Invalid arrow position'
    })
  }

  if (!Number.isInteger(score) || score < 0 || score > 10) {
    return res.status(400).json({
      error: 'Arrow score must be between 0 and 10'
    })
  }

  if (isX && score !== 10) {
    return res.status(400).json({
      error: 'X can only be recorded on a score of 10'
    })
  }

  await pool.query(
    insertArrow,
    [endId, pos, score, isX ? 1 : 0]
  )

  sum += score

    }

    // update PrelimTotal on scorerecord
    await pool.query('UPDATE scorerecord SET PrelimTotal = COALESCE(PrelimTotal,0) + ? WHERE RecordID = ?', [sum, recordId])

    res.status(201).json({ EndID: endId, added: Arrows.length, sum })
  } catch (err) {
    console.error('POST /api/records/:id/ends', err)
    res.status(500).json({ error: 'Unable to save end' })
  }
})

const startServer = async () => {
  try {
    await ensureDatabase()
    await ensureTables()
    app.listen(port, () => console.log(`Archer API running on http://localhost:${port}`))
  } catch (err) {
    console.error('startup failed', err)
    process.exit(1)
  }
}

startServer()
