const axios = require('axios');

const SUPA_URL = 'https://runvwdnilflwjhywgdxo.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1bnZ3ZG5pbGZsd2poeXdnZHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODU0NjYsImV4cCI6MjA4OTY2MTQ2Nn0.MCLbGhg4FGAi2Y1O4gl_U5HzqZcjzUhHjZWRGoQuAzA';

async function clearTable(tableName) {
    try {
        console.log(`Clearing table: ${tableName}...`);
        const res = await axios.delete(`${SUPA_URL}/rest/v1/${tableName}?id=not.is.null`, {
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        console.log(`✅ Success clearing ${tableName}: ${res.status}`);
    } catch (e) {
        console.error(`❌ Error clearing ${tableName}:`, e.response?.data || e.message);
    }
}

async function main() {
    await clearTable('incidents');
    await clearTable('sos_logs');
}

main();
