const axios = require('axios');
const fs = require('fs');
const path = require('path');

const SUPA_URL = 'https://runvwdnilflwjhywgdxo.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1bnZ3ZG5pbGZsd2poeXdnZHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODU0NjYsImV4cCI6MjA4OTY2MTQ2Nn0.MCLbGhg4FGAi2Y1O4gl_U5HzqZcjzUhHjZWRGoQuAzA';

async function main() {
    try {
        console.log('Fetching all incidents for backup...');
        const res = await axios.get(`${SUPA_URL}/rest/v1/incidents?select=*`, {
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`
            }
        });
        
        const backupFile = path.join(__dirname, 'incidents_dataset.json');
        fs.writeFileSync(backupFile, JSON.stringify(res.data, null, 2));
        console.log(`✅ Success! Backed up ${res.data.length} records to ${backupFile}`);
        
        // After backup, clear the table
        console.log('Clearing increments table...');
        const delRes = await axios.delete(`${SUPA_URL}/rest/v1/incidents?id=not.is.null`, {
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        console.log(`✅ Success! Table cleared (Status ${delRes.status})`);
        
    } catch (e) {
        console.error('❌ Error:', e.response?.data || e.message);
    }
}

main();
