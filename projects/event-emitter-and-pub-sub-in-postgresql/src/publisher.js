/**
 * This App will emit one event about once a second.
 */

const PGPubsub = require('@fetchq/pg-pubsub');

const ENV_PGSTRING = process.env.PGSTRING || 'postgresql://postgres:postgres@localhost:5432/postgres';
const ENV_CHANNELS = (process.env.CHANNELS || 'ch1,ch2').split(',');

const START_TIME = new Date();
const client = new PGPubsub(ENV_PGSTRING);

setInterval(() => {
  const channel = ENV_CHANNELS[Math.floor(Math.random()*ENV_CHANNELS.length)];
  client.publish(channel, {
    type: 'time-lapsed',
    value: new Date() - START_TIME,
  });
}, 1000);

