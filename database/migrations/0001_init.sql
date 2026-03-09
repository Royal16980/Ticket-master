CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  city TEXT,
  interests JSONB DEFAULT '[]'::jsonb
);

CREATE TABLE organisers (
  id UUID PRIMARY KEY,
  owner_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  name TEXT NOT NULL
);

CREATE TABLE events (
  id UUID PRIMARY KEY,
  organiser_id UUID NOT NULL REFERENCES organisers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  city TEXT NOT NULL,
  venue TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  capacity INT NOT NULL CHECK (capacity > 0)
);
CREATE INDEX events_discovery_idx ON events(category, city, starts_at);

CREATE TABLE ticket_types (
  id UUID PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price_cents INT NOT NULL,
  capacity INT NOT NULL CHECK (capacity > 0),
  sold INT NOT NULL DEFAULT 0 CHECK (sold >= 0 AND sold <= capacity)
);

CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE RESTRICT,
  amount_cents INT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
  id UUID PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  ticket_type_id UUID NOT NULL REFERENCES ticket_types(id) ON DELETE RESTRICT,
  quantity INT NOT NULL CHECK (quantity > 0),
  line_total_cents INT NOT NULL
);

CREATE TABLE tickets (
  id UUID PRIMARY KEY,
  order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  qr_token TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'valid'
);

CREATE TABLE checkins (
  id UUID PRIMARY KEY,
  ticket_id UUID NOT NULL UNIQUE REFERENCES tickets(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  checked_in_by UUID REFERENCES users(id) ON DELETE SET NULL,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX checkins_lookup_idx ON checkins(ticket_id, event_id);

CREATE TABLE referral_codes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE
);

CREATE TABLE points_ledger (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  points_delta INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rewards_catalog (
  id UUID PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  points_cost INT NOT NULL CHECK (points_cost > 0)
);

CREATE TABLE user_persona_scores (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  persona TEXT NOT NULL,
  score INT NOT NULL DEFAULT 0
);

CREATE TABLE promo_codes (
  id UUID PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  discount_type TEXT NOT NULL,
  discount_value INT NOT NULL,
  max_uses INT
);

CREATE TABLE campaign_targets (
  id UUID PRIMARY KEY,
  organiser_id UUID NOT NULL REFERENCES organisers(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  segment TEXT NOT NULL
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  body TEXT
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  payload JSONB NOT NULL,
  sent_at TIMESTAMPTZ
);

CREATE TABLE payout_records (
  id UUID PRIMARY KEY,
  organiser_id UUID NOT NULL REFERENCES organisers(id) ON DELETE CASCADE,
  amount_cents INT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE fraud_flags (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  severity TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
