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
const channel = process.env.CHANNEL || 'ch1';

// Local Symbols
const db = new Client({ connectionString });

// Asynchronous App
// (self running anonymous function with basic error handling)
(async () => {
  // Acquire a connection with the PostgreSQL instance
  await db.connect();

  // Add a listener on pub/sub notifications for the connected client
  db.on('notification', (msg) => {
    console.log(`New event on "${msg.channel}"`, msg.payload);
  })

  // Subscribe to the channel using the `LISTEN` statement
  console.log(`Listening to ${channel}...`);
  await db.query(`LISTEN "${channel}"`)

})().catch(console.error);
