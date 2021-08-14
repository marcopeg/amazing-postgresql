/**
 * This App will emit one event about once a second.
 */

const { Client } = require('pg');

// Environmental Variables
const channels = (process.env.CHANNELS || 'ch1,ch2').split(',');
const connectionString = process.env.PGSTRING || 'postgresql://postgres:postgres@localhost:5432/postgres';

// Local Symbols
const START_TIME = new Date();
const db = new Client({ connectionString });

// Asynchronous App
// (self running anonymous function with basic error handling)
(async () => {
  // Acquire a connection with the PostgreSQL instance
  await db.connect();

  setInterval(async () => {
    // Calculates a random channel and the app's uptime
    const channel = channels[Math.floor(Math.random()*channels.length)];
    const payload = JSON.stringify({
      type: 'uptime',
      value: new Date() - START_TIME,
    });
    
    // We use the basic `NOTIFY` to emit the event
    console.log(`Emit ${payload} on "${channel}"`);
    await db.query(`NOTIFY "${channel}", '${payload}';`)
  }, 1000)

})().catch(console.error);

