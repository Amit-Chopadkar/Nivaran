const fs = require('fs');
const path = require('path');

const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'incidents_dataset.json'), 'utf8'));

let sqlSnippet = `
-- 1. Drop and Recreate Incidents Table with Expanded Schema
DROP TABLE IF EXISTS incidents;

CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
  title TEXT,
  type TEXT NOT NULL,
  severity INTEGER DEFAULT 2,
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

-- 2. Grant Permissions (Assuming Anon Key Usage)
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Full Access" ON incidents;
CREATE POLICY "Public Full Access" ON incidents FOR ALL USING (true) WITH CHECK (true);

-- 3. Re-insert Dataset
INSERT INTO incidents (id, user_id, lat, lng, type, severity, description, verified, source, title, address, created_at) VALUES
`;

const rows = data.map(item => {
    // Generate a title from the first sentence or type
    let title = item.type.replace('_', ' ').toUpperCase();
    if (item.description.length < 30) title = item.description;
    
    // Map severity (ensure it is within 1-4)
    let sev = item.severity || 2;
    if (sev > 4) sev = 4;

    return `(
      '${item.id}',
      '${item.user_id || '00000000-0000-0000-0000-000000000000'}',
      ${item.lat},
      ${item.lng},
      '${item.type}',
      ${sev},
      '${item.description.replace(/'/g, "''")}',
      ${item.verified},
      '${item.source}',
      '${title}',
      'Nashik, Maharashtra',
      '${item.created_at}'
    )`;
});

sqlSnippet += rows.join(',\n') + ';';

fs.writeFileSync(path.join(__dirname, 'setup_safety_db.sql'), sqlSnippet);
console.log('✅ Generated setup_safety_db.sql with 51 records.');
