-- ============================================================
-- Chhat App: Supabase PostgreSQL Schema
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ──────────────────────────────────────────────
-- USERS
-- ──────────────────────────────────────────────
CREATE TABLE users (
  id UUID PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  profile_complete BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  active_role TEXT CHECK (active_role IN ('tenant', 'owner')),
  roles TEXT[] DEFAULT '{}',
  fcm_token TEXT,
  push_enabled BOOLEAN DEFAULT true,
  consent_version TEXT,
  consent_given_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  deletion_reason TEXT
);

-- ──────────────────────────────────────────────
-- LISTINGS
-- ──────────────────────────────────────────────
CREATE TABLE listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  phone TEXT,
  property_kind TEXT DEFAULT 'residential' CHECK (property_kind IN ('residential', 'commercial')),
  property_category TEXT,
  furnishing_status TEXT,
  parking_type TEXT,
  city TEXT,
  area TEXT,
  sub_area TEXT,
  landmark TEXT,
  distance_km DOUBLE PRECISION DEFAULT 0,
  rent INTEGER DEFAULT 0,
  deposit INTEGER DEFAULT 0,
  size_sqft INTEGER DEFAULT 0,
  floor TEXT,
  occupancy INTEGER DEFAULT 1,
  facilities TEXT[] DEFAULT '{}',
  allowed_tenants TEXT[] DEFAULT '{}',
  restrictions TEXT[] DEFAULT '{}',
  availability TEXT,
  photos TEXT[] DEFAULT '{}',
  active BOOLEAN DEFAULT true,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  report_count INTEGER DEFAULT 0,
  search_keywords TEXT[] DEFAULT '{}',
  -- Commercial fields
  built_up_area TEXT,
  super_built_up_area TEXT,
  plot_area TEXT,
  total_floors TEXT,
  ceiling_height TEXT,
  frontage TEXT,
  road_width TEXT,
  suitable_for TEXT[] DEFAULT '{}',
  utilities TEXT[] DEFAULT '{}',
  building_grade TEXT,
  building_age TEXT,
  possession TEXT,
  ownership TEXT,
  visibility TEXT[] DEFAULT '{}',
  -- Residential defaults
  room_type TEXT DEFAULT 'single',
  gender_pref TEXT DEFAULT 'any',
  toilet_type TEXT DEFAULT 'shared',
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- ──────────────────────────────────────────────
-- TENANT PROFILES
-- ──────────────────────────────────────────────
CREATE TABLE tenant_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,
  age INTEGER,
  gender TEXT,
  tenant_type TEXT,
  occupation TEXT,
  city TEXT,
  area TEXT,
  sub_area TEXT,
  property_kind TEXT,
  property_requirements TEXT[] DEFAULT '{}',
  move_in_date TEXT,
  budget_range TEXT,
  is_profile_complete BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────
-- OWNER PROFILES
-- ──────────────────────────────────────────────
CREATE TABLE owner_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────
-- REQUESTS
-- ──────────────────────────────────────────────
CREATE TABLE requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES users(id) ON DELETE CASCADE,
  tenant_phone TEXT,
  listing_id UUID REFERENCES listings(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  area TEXT,
  rent INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  sender_type TEXT DEFAULT 'tenant' CHECK (sender_type IN ('tenant', 'owner')),
  responded_by UUID REFERENCES users(id),
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Unique constraint: one request per tenant+listing+senderType combo
CREATE UNIQUE INDEX idx_requests_unique ON requests(tenant_id, listing_id, sender_type);

-- ──────────────────────────────────────────────
-- NOTIFICATIONS
-- ──────────────────────────────────────────────
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────
-- REPORTS (user-level reports)
-- ──────────────────────────────────────────────
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES users(id) NOT NULL,
  reported_user_id UUID REFERENCES users(id),
  listing_id UUID REFERENCES listings(id),
  report_type TEXT NOT NULL,
  additional_info TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────
-- LISTING REPORTS (dedupe: 1 per user per listing)
-- ──────────────────────────────────────────────
CREATE TABLE listing_reports (
  listing_id UUID REFERENCES listings(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES users(id),
  reported_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (listing_id, reporter_id)
);

-- ──────────────────────────────────────────────
-- BROADCASTS (admin-created)
-- ──────────────────────────────────────────────
CREATE TABLE broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target TEXT NOT NULL CHECK (target IN ('tenant', 'owner', 'both')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────
-- INDEXES for query performance
-- ──────────────────────────────────────────────
CREATE INDEX idx_listings_search ON listings USING gin(search_keywords);
CREATE INDEX idx_listings_active_kind ON listings(active, property_kind);
CREATE INDEX idx_listings_owner ON listings(owner_id, active);
CREATE INDEX idx_listings_area ON listings(area, active);
CREATE INDEX idx_listings_expiry ON listings(active, expires_at);
CREATE INDEX idx_requests_owner ON requests(owner_id, sender_type, created_at DESC);
CREATE INDEX idx_requests_tenant ON requests(tenant_id, sender_type, created_at DESC);
CREATE INDEX idx_notifications_user ON notifications(user_id, read, created_at DESC);
CREATE INDEX idx_users_phone ON users(phone);

-- ──────────────────────────────────────────────
-- AUTO-UPDATE updated_at trigger
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tenant_profiles_updated_at BEFORE UPDATE ON tenant_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER owner_profiles_updated_at BEFORE UPDATE ON owner_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ──────────────────────────────────────────────
-- SEARCH KEYWORDS auto-generate function
-- Same logic as Cloud Function, but runs inside DB
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_search_keywords()
RETURNS TRIGGER AS $$
DECLARE
  fields TEXT[];
  field TEXT;
  words TEXT[];
  word TEXT;
  keywords TEXT[] := '{}';
  i INTEGER;
BEGIN
  fields := ARRAY[NEW.area, NEW.city, NEW.sub_area, NEW.landmark, NEW.property_category];

  FOREACH field IN ARRAY fields LOOP
    IF field IS NOT NULL AND field != '' THEN
      words := string_to_array(lower(trim(field)), ' ');
      FOREACH word IN ARRAY words LOOP
        IF word != '' THEN
          FOR i IN 2..length(word) LOOP
            IF NOT (substring(word, 1, i) = ANY(keywords)) THEN
              keywords := array_append(keywords, substring(word, 1, i));
            END IF;
          END LOOP;
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  NEW.search_keywords := keywords;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER listings_search_keywords
  BEFORE INSERT OR UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION generate_search_keywords();

-- ──────────────────────────────────────────────
-- AUTO-DEACTIVATE expired listings (daily via pg_cron)
-- Run manually or set up pg_cron in Supabase Dashboard
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION cleanup_expired_listings()
RETURNS void AS $$
BEGIN
  UPDATE listings SET active = false
  WHERE active = true AND expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- To schedule daily (run in SQL Editor after pg_cron is enabled):
-- SELECT cron.schedule('cleanup-expired-listings', '30 0 * * *', 'SELECT cleanup_expired_listings()');

-- ──────────────────────────────────────────────
-- DPDP 180-day inactive user cleanup
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION cleanup_inactive_users()
RETURNS void AS $$
BEGIN
  UPDATE users SET active = false, deleted_at = now(), deletion_reason = 'DPDP 180-day retention policy'
  WHERE active = true AND updated_at < (now() - INTERVAL '180 days');
END;
$$ LANGUAGE plpgsql;

-- SELECT cron.schedule('cleanup-inactive-users', '0 0 * * *', 'SELECT cleanup_inactive_users()');

-- ──────────────────────────────────────────────
-- STORAGE BUCKET
-- Create via Dashboard: Storage → New Bucket → "listings" (public)
-- ──────────────────────────────────────────────
