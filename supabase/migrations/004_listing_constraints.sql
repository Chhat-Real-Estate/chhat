-- ─────────────────────────────────────────────────────────────
-- MIGRATION: 004_listing_constraints.sql
-- Description: Add data integrity constraints on listings table
--              (#4: rent > 0, deposit >= 0, size_sqft > 0)
--              (#5: phone ~ '^\+91[0-9]{10}$')
-- ─────────────────────────────────────────────────────────────

-- 1. Alter default values so future inserts cannot default to invalid values
ALTER TABLE listings ALTER COLUMN rent DROP DEFAULT;
ALTER TABLE listings ALTER COLUMN size_sqft DROP DEFAULT;

-- 2. Add constraints for rent, deposit, and size_sqft (#4)
ALTER TABLE listings
  ADD CONSTRAINT listings_rent_check CHECK (rent > 0);

ALTER TABLE listings
  ADD CONSTRAINT listings_deposit_check CHECK (deposit >= 0);

ALTER TABLE listings
  ADD CONSTRAINT listings_size_sqft_check CHECK (size_sqft > 0);

-- 3. Add constraint for phone format (#5)
ALTER TABLE listings
  ADD CONSTRAINT listings_phone_check CHECK (phone ~ '^\+91[0-9]{10}$');
