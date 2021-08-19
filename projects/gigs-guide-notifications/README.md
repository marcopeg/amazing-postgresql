# Gigs Guide Notifications

A good friend of mine is the enterpreneur behind [GigsGuide](https://gigs.guide), a community that facilitate your music driven travelling.

He wants to send periodic emails to his users with the upcoming events of the artists that are followed by each user.

## The Data Model

Here is a simplified version of the data model that GigsGuide implements to keep its information.

### MusicEvents

Contains generic information about a specific concert or show.  
_(most fields are omitted)_

- event_id
- country_code

### EventsPerformers

Keeps _many-to-many_ relationship to track which artist is playing in which event.

- event_id
- artist_id

### UsersPerformers

Keeps a _one-to-many_ relationship to track which artists are followed by a user.

- user_id
- artist_id

### SentEvents

Keeps track of events that have already been notified to a spcific user

- user_id
- event_id

## The Problem

My friend would like to query and receive a list of users that needs to be notified about one or more events, skipping the events that have already been notified. 

Here is the desired data structure:

| user_id | event_ids  |
|---------|------------|
| usr1    | evt1, evt2 |
| usr2    | evt1       |

And let's break down the query's specs:

- Find all the events played by any followed user
- Filter by event's country code
- Skip events that have been notified

## Seed Demo Data

Before we dive into the solution we need to think about performances. Way too often I met engineers that solve their problems with an empty database, only to see their solution crashing under even small amounts of data.

Of course, we will prove the correctness of our solution with unit tests that works fast under minimal data sets, but it is important to also run benchmarks of our queries against quite some data. Millions of rows.

### Seed EventsPerformers

This one is 

## Find all the events played by any followed user