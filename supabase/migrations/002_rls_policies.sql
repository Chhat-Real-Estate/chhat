-- ============================================================
-- Chhat App: Row Level Security (RLS) Policies
-- Run AFTER 001_initial_schema.sql
-- Replaces firestore.rules — same ownership logic
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcasts ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────
-- USERS: sirf apna document read/write
-- ──────────────────────────────────────────────
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    -- roles array shrink nahi ho sakta (append-only)
    AND (roles @> (SELECT roles FROM users WHERE id = auth.uid()))
  );

-- No delete (soft-delete via active = false)

-- ──────────────────────────────────────────────
-- LISTINGS: koi bhi auth'd user read, sirf owner write
-- ──────────────────────────────────────────────
CREATE POLICY "listings_select_all" ON listings
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "listings_insert_own" ON listings
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "listings_update_own" ON listings
  FOR UPDATE USING (auth.uid() = owner_id)
  WITH CHECK (
    auth.uid() = owner_id
    -- owner_id change nahi ho sakta
    AND owner_id = (SELECT owner_id FROM listings WHERE id = listings.id)
  );

CREATE POLICY "listings_delete_own" ON listings
  FOR DELETE USING (auth.uid() = owner_id);

-- ──────────────────────────────────────────────
-- TENANT PROFILES: sirf apna document
-- ──────────────────────────────────────────────
CREATE POLICY "tenant_profiles_select_own" ON tenant_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "tenant_profiles_insert_own" ON tenant_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tenant_profiles_update_own" ON tenant_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "tenant_profiles_delete_own" ON tenant_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────
-- OWNER PROFILES: koi bhi auth'd read, sirf apna write
-- ──────────────────────────────────────────────
CREATE POLICY "owner_profiles_select_all" ON owner_profiles
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "owner_profiles_insert_own" ON owner_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner_profiles_update_own" ON owner_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "owner_profiles_delete_own" ON owner_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────
-- REQUESTS: sirf ownerId ya tenantId wala
-- ──────────────────────────────────────────────
CREATE POLICY "requests_select_party" ON requests
  FOR SELECT USING (
    auth.uid() = owner_id OR auth.uid() = tenant_id
  );

CREATE POLICY "requests_insert_sender" ON requests
  FOR INSERT WITH CHECK (
    (sender_type = 'tenant' AND auth.uid() = tenant_id)
    OR
    (sender_type = 'owner' AND auth.uid() = owner_id)
  );

CREATE POLICY "requests_update_party" ON requests
  FOR UPDATE USING (
    auth.uid() = owner_id OR auth.uid() = tenant_id
  );

CREATE POLICY "requests_delete_party" ON requests
  FOR DELETE USING (
    auth.uid() = owner_id OR auth.uid() = tenant_id
  );

-- ──────────────────────────────────────────────
-- NOTIFICATIONS: sirf apni
-- ──────────────────────────────────────────────
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "notifications_delete_own" ON notifications
  FOR DELETE USING (auth.uid() = user_id);

-- No client insert — Edge Functions (service_role) create karta hai

-- ──────────────────────────────────────────────
-- REPORTS: auth'd create, no client read
-- ──────────────────────────────────────────────
CREATE POLICY "reports_insert_auth" ON reports
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = reporter_id
  );

-- No SELECT/UPDATE/DELETE for clients (admin only via service_role)

-- ──────────────────────────────────────────────
-- LISTING REPORTS: 1 report per user per listing
-- ──────────────────────────────────────────────
CREATE POLICY "listing_reports_insert_auth" ON listing_reports
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = reporter_id
  );

-- No SELECT/UPDATE/DELETE for clients

-- ──────────────────────────────────────────────
-- BROADCASTS: no client access (Edge Functions only)
-- ──────────────────────────────────────────────
-- No policies = no client access (RLS is enabled, default deny)

-- ──────────────────────────────────────────────
-- STORAGE POLICIES (set via Dashboard → Storage → Policies)
-- Bucket: "listings"
-- ──────────────────────────────────────────────
-- Read:   auth'd users (public listing photos)
-- Upload: auth.uid() matches folder path (listings/{userId}/*)
-- Delete: auth.uid() matches folder path

-- SQL for storage policies (run separately):
-- CREATE POLICY "listings_storage_read" ON storage.objects
--   FOR SELECT USING (bucket_id = 'listings' AND auth.uid() IS NOT NULL);
--
-- CREATE POLICY "listings_storage_upload" ON storage.objects
--   FOR INSERT WITH CHECK (
--     bucket_id = 'listings'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );
--
-- CREATE POLICY "listings_storage_delete" ON storage.objects
--   FOR DELETE USING (
--     bucket_id = 'listings'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );
