-- ============================================================
-- Chhat App: Grant Permissions and RLS for Anon & Authenticated
-- Run this in Supabase Dashboard -> SQL Editor
-- ============================================================

-- 1. Grant schema usage and table permissions to anon & authenticated
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated;

-- 2. Allow anon to read, insert and update users, listings, profiles, requests, notifications
-- Temporarily disable RLS so that anon queries are not blocked while Auth session is being set up
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE listings DISABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE listing_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE broadcasts DISABLE ROW LEVEL SECURITY;

-- 3. Remove foreign key constraint to auth.users (kyunki hum MSG91 phone OTP use kar rahe hain)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 4. Enable Supabase Realtime for instant updates without stream connection errors
ALTER PUBLICATION supabase_realtime ADD TABLE requests;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE listings;


