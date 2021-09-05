/**
 * This App subscribes to the "foobar" channel and simply visualizes the
 * received payload.
 * 
 * NOTE: this is a minimal implementation that doesn't take into account
 *       issues as connection attempts, loss of connection, or multiple channels
 * 
 *       Please check out the following libraries:
 *       - https://github.com/voxpelli/node-pg-pubsub
 *       - https://github.com/fetchq/node-pg-pubsub
 * 
 */

const { Client } = require('pg');

// Environmental Variables
const connectionString = process.env.PGSTRING || 'postgresql://postgres:postgres@localhost:5432/postgres';

// Local Symbols
const START_TIME = new Date();
const db = new Client({ connectionString });
const logBatch = Number(process.env.LOG_BATCH) || Number(process.env.INSERTS_PER_ITERATION) || 5;
const readBatch = Number(process.env.READ_BATCH) || 100;

// Asynchronous App
// (self running anonymous function with basic error handling)
(async () => {
  // Acquire a connection with the PostgreSQL instance
  await db.connect();
  let lastEtag = 0;
  let lastCtime = 0;
  let sum = 0;
  let count = 0;
  let delta = 0;
  let countCtime = 0;

  const consume = () => new Promise((resolve, reject) => {
    const loop = async () => {
      const res = await db.query('SELECT * FROM get_event($1, $2)', [lastEtag, readBatch]);

      if (res.rowCount) {
        for (const row of res.rows) {
          const _etag = Number(row.etag);
          const _ctime = row.ctime;
          const _delta = _etag - lastEtag;

          // Update max reached delta
          // it should always be 1
          delta = _delta > delta ? _delta : delta;
          if (delta > 1 && process.env.NODE_ENV === 'development') {
            console.log(lastEtag)
            console.log(_etag)
            throw new Error(`Noooooooo`)
          }

          // Keep track of repeated ctimes
          if (lastCtime === _ctime) {
            if (process.env.NODE_ENV === 'development') {
              console.log('!!! Ctime hit:', lastCtime, _ctime)
            }
            countCtime += 1;
          }

          sum += Number(row.payload.value);
          count += 1;

          if (process.env.NODE_ENV === 'development') {
            console.log(`> etag: ${_etag}; delta: ${_delta}; sum: ${sum}`)
          } else if (count % logBatch === 0) {
            console.log(`> etag: ${_etag}; delta: ${_delta}; sum: ${sum}`)
          }

          lastEtag = _etag;
          lastCtime = _ctime;
        }
        loop()
      } else {
        resolve()
      }
    }

    loop()
  }) 

  console.log(`@@ Start consuming events log...`)
  await consume();
  const FINISH_TIME = new Date();
  const lapsedTime = FINISH_TIME - START_TIME
  console.log('');
  console.log(`@@ Tot Logs: ${count}`)
  console.log(`@@ Checksum: ${sum}`)
  console.log(`@@ MaxDelta: ${delta}`)
  console.log(`@@ CTimeHit: ${countCtime}`)
  console.log(`@@ LapsedMS: ${lapsedTime}ms`)
  console.log(`@@ Throughp: ${Math.round(count * 1000 / lapsedTime)}ms`)

  
  // Exit the process in production
  // (while developing it will hang for changes)
  process.env.NODE_ENV === 'production' && process.kill(0);

})().catch(console.error);
