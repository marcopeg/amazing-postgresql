```sql
delete from all_music_events_temp
where event_id not in (
  select event_id from cached_distances
);

delete from cities
where "name" not in (
  select city from cached_queries
);

update all_music_events_temp
set venue = '{}', event_data = '{}', hero_image = '', event_description = '',
ticket_ids = '{}', performer_ids = '{}', ticket_url = '', wandercity_id = '', venue_id = '', city = '', country = '';

update cities
set city_data = '{}', state = '', country = '', timezone = '{}', population = null, city_banner = '{}',
wikivoyage = '{}', wikipedia = '{}', wikidata_id = null, geonames_id = null, wikidata = '{}', guide_book = '{}', state_abbr = null;
```