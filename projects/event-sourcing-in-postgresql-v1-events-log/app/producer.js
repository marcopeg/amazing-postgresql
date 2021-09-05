/**
 * This App will emit one event about once a second.
 */

const { Client } = require('pg');

// Environmental Variables
const maxIterations = Number(process.env.MAX_ITERATIONS) || 4;
const insertsPerIteration = Number(process.env.INSERTS_PER_ITERATION) || 5;
const connectionString = process.env.PGSTRING || 'postgresql://postgres:postgres@localhost:5432/postgres';
const truncate = Boolean(process.env.TRUNCATE_BEFORE_PRODUCE) === true;

// Local Symbols
const START_TIME = new Date();
const db = new Client({ connectionString });
const truncateSql = `TRUNCATE events_log RESTART IDENTITY CASCADE`;

// Asynchronous App
// (self running anonymous function with basic error handling)
(async () => {
  // Acquire a connection with the PostgreSQL instance
  await db.connect();

  if (truncate) {
    console.log('@@ truncate "events_log" table...')
    await db.query(truncateSql)
  }
  
  const maxInserts = maxIterations * insertsPerIteration
  console.log(`@@ Insert ${maxInserts} logs...`)
  for (let i = 0; i < maxIterations; i++) {
    const startAt = i * insertsPerIteration + 1;
    const endAt = i * insertsPerIteration + insertsPerIteration;
    const progress = Math.round(endAt / maxInserts * 100);
    console.log(`> ${progress.toString().padStart(3, ' ')}%     ${startAt} -> ${endAt}...`);
    await db.query(`
      INSERT INTO "public"."events_log" ("payload")
      SELECT json_build_object('insertIdx', "t", 'value', 1) AS "payload"
      FROM generate_series(${startAt}, ${endAt}) AS "t";
    `)
  }

  const FINISH_TIME = new Date();
  console.log(`@@ Lapsed: ${FINISH_TIME - START_TIME}ms`)

  // Exit the process in production
  // (while developing it will hang for changes)
  process.env.NODE_ENV === 'production' && process.kill(0);
})().catch(console.error);
