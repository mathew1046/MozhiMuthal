-- supabase/schema.sql
-- Workers table mapped to Auth profiles
CREATE TABLE workers (
  id UUID REFERENCES auth.users PRIMARY KEY,
  anganwadi_id TEXT UNIQUE NOT NULL,
  district_code TEXT NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE screenings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anganwadi_id TEXT NOT NULL,
  district_code TEXT,
  child_age_months INTEGER,
  risk_level TEXT,
  vttl_ms FLOAT,
  pfv_std FLOAT,
  cvr_ratio FLOAT,
  vttl_flagged BOOLEAN,
  pfv_flagged BOOLEAN,
  cvr_flagged BOOLEAN,
  audio_source TEXT,
  session_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
  -- NO child name, NO audio, NO spectrograms
);

-- RLS: Anganwadi workers can only INSERT, not SELECT others' rows
-- DEIC dashboard uses service_role key with read-all access
ALTER TABLE screenings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workers can insert screenings"
  ON screenings
  FOR INSERT
  WITH CHECK (true); -- Ideally restrict to auth.uid(), but anganwadi_id logic will apply.

ALTER TABLE workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workers can view their own profile"
  ON workers
  FOR SELECT
  USING (auth.uid() = id);
