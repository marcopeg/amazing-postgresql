/**
 * This App subscribes to the "foobar" channel and simply visualizes the
 * received payload. 
 */

const PGPubsub = require('@fetchq/pg-pubsub');

const ENV_PGSTRING = process.env.PGSTRING || 'postgresql://postgres:postgres@localhost:5432/postgres';
const ENV_CHANNEL = process.env.CHANNEL || 'ch1';

const client = new PGPubsub(ENV_PGSTRING);

client.addChannel(ENV_CHANNEL, payload => {
  console.log(`New event on "${ENV_CHANNEL}"`, payload);
});
