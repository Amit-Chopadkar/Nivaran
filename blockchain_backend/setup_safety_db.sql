-- ==========================================
-- 🛡️ SafeHer Enhanced Safety Database Setup
-- ==========================================

-- 1. Drop existing table and all dependent objects (including views like heatmap summaries)
DROP TABLE IF EXISTS incidents CASCADE;

-- 2. Create the enhanced Incidents table with all required columns
CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
  title TEXT,
  type TEXT NOT NULL,
  severity INTEGER DEFAULT 2, -- 1:Low, 2:Medium, 3:High, 4:Critical
  source TEXT DEFAULT 'user_report',
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  address TEXT,
  description TEXT,
  verified BOOLEAN DEFAULT FALSE,
  risk_score INTEGER DEFAULT 50,
  media_urls TEXT[] DEFAULT '{}',
  blockchain_tx TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Restore any dependent views required by the platform
CREATE OR REPLACE VIEW incident_heatmap_summary AS 
SELECT id, lat, lng, risk_score, type, severity, created_at 
FROM incidents;

-- 4. Enable Real-Time & Security Permissions
-- This allows the mobile app and admin dashboard correctly communicate
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Full Access" ON incidents;
CREATE POLICY "Public Full Access" ON incidents FOR ALL USING (true) WITH CHECK (true);

-- 5. Empty Table Ready for Dynamic Entries
-- Note: As requested, the 51 historical entries have been removed.
-- The table is now completely empty and waiting for real user reports!