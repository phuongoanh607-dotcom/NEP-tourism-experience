-- NÉP 019: connect tour stops to destination coordinates and optional 3D assets.
-- Additive only. Existing tours, stops, QR tokens, bookings and check-ins remain unchanged.
alter table public.journey_stops
  add column if not exists lat double precision,
  add column if not exists lng double precision,
  add column if not exists model_url text,
  add column if not exists model_source text,
  add column if not exists model_accuracy text,
  add column if not exists model_updated_at timestamptz;

alter table public.journey_stops
  drop constraint if exists journey_stops_lat_range_check,
  drop constraint if exists journey_stops_lng_range_check,
  add constraint journey_stops_lat_range_check check (lat is null or lat between -90 and 90),
  add constraint journey_stops_lng_range_check check (lng is null or lng between -180 and 180),
  add constraint journey_stops_model_url_https_check check (model_url is null or model_url ~ '^https://');

create index if not exists journey_stops_journey_order_idx
  on public.journey_stops (journey_id, stop_order);

comment on column public.journey_stops.model_url is
  'Optional public HTTPS URL to a GLB/GLTF model for this stop. Null means no 3D model.';
comment on column public.journey_stops.model_source is
  'Source/provider or permission/provenance note for the 3D asset.';
comment on column public.journey_stops.model_accuracy is
  'Must state whether the model is illustrative, approximate, or measured/verified.';
