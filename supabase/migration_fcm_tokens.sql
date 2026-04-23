create table if not exists fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id text unique not null,
  token text not null,
  updated_at timestamptz default now()
);
