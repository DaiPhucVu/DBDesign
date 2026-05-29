import mysql from 'mysql2/promise'

const dbName = process.env.DB_DATABASE || 'archerdb'
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || ''
}

const seed = async () => {
  const connection = await mysql.createConnection(dbConfig)
  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`)
  await connection.end()

  const pool = mysql.createPool({ ...dbConfig, database: dbName, waitForConnections: true, connectionLimit: 5, queueLimit: 0 })

  // minimal seed data for UI/testing
  await pool.query("INSERT IGNORE INTO equipment (EquipmentName) VALUES (?), (?), (?), (?)", ['Recurve','Compound','Barebow','Longbow'])

  await pool.query("INSERT IGNORE INTO archerinfo (AVNumber, Fname, Lname, BirthYear, Gender, DefaultEquipmentID) VALUES (?, ?, ?, ?, ?, ?)", ['AV001','Irene','Moser',1990,'F',1])

  await pool.query("INSERT IGNORE INTO roundinfo (RoundName, MaxScore) VALUES (?, ?)", ['Melbourne, 90 arrows', 900])
  const [rnd] = await pool.query('SELECT RoundID FROM roundinfo WHERE RoundName = ?', ['Melbourne, 90 arrows'])
  const roundId = rnd[0].RoundID

  // example: 5 ranges with Ends each (for simplicity make 5 ends of 6 arrows => 30 arrows per range)
  await pool.query('INSERT IGNORE INTO rangeinfo (RoundID, SequenceNo, Distance, Ends, TargetFace) VALUES (?, ?, ?, ?, ?)', [roundId, 1, 50, 5, 122])

  console.log('Seeding complete. Inserted equipment, one archer, one round and range.')
  await pool.end()
}

seed().catch((err) => {
  console.error('Seed failed', err)
  process.exit(1)
})
