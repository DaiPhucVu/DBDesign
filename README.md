# ArcherApp

A Vue + Vite frontend with an Express + MySQL backend for archery score entry.

## What this project contains

- `server.js` — Express backend API for rounds, archers, equipment, score records, and ends
- `src/App.vue` — frontend single-score entry UI
- `vite.config.js` — Vite configuration and `/api` proxy to backend
- `seed.js` — optional seed script to create sample equipment, an archer, a round, and a range
- `archerdb_wip.sql` — schema definition for the archery database

## Prerequisites

- Node.js 18+ installed
- MySQL Server installed and running locally
- A MySQL user with access to create databases/tables (default uses `root` with empty password)

## Initial setup

1. Open a terminal in `ArcherApp`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set database environment variables if you are not using the defaults:
   - `DB_HOST` (default: `localhost`)
   - `DB_USER` (default: `root`)
   - `DB_PASSWORD` (default: empty string)
   - `DB_DATABASE` (default: `archerdb`)

   Example on Windows PowerShell:
   ```powershell
   $env:DB_HOST = 'localhost'
   $env:DB_USER = 'root'
   $env:DB_PASSWORD = 'your-password'
   $env:DB_DATABASE = 'archerdb'
   ```

4. Optional: seed sample data:
   ```bash
   npm run seed
   ```
   This will create the database and insert sample equipment, one archer, one round, and one range.

## Running the app

### Start the backend

```bash
npm run serve
```

This starts the API on `http://localhost:3000`.

### Start the frontend

```bash
npm run dev
```

This starts the Vite frontend on `http://localhost:5174`.

The frontend is configured to proxy `/api` requests to `http://localhost:3000`.

## How the backend works

- `server.js` creates the database if it does not exist
- it also ensures required tables are present before serving requests
- `POST /api/records` creates a new score record
- `POST /api/records/:id/ends` adds ends and arrow scores for that record

## Notes

- If MySQL is not running or credentials are invalid, the backend will fail to connect
- The project uses a local MySQL database and does not include authentication
- The Vite frontend and Express backend run separately but work together through the proxy
