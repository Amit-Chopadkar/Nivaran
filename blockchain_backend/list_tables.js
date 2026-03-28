const axios = require('axios');

const SUPA_URL = 'https://runvwdnilflwjhywgdxo.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1bnZ3ZG5pbGZsd2poeXdnZHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODU0NjYsImV4cCI6MjA4OTY2MTQ2Nn0.MCLbGhg4FGAi2Y1O4gl_U5HzqZcjzUhHjZWRGoQuAzA';

async function main() {
    try {
        // We can't easily list tables via REST without extra exposure, 
        // but we can try to access common names.
        const tables = ['incidents', 'sos_logs', 'users', 'contacts', 'verified_identities'];
        for (const t of tables) {
            try {
                const res = await axios.get(`${SUPA_URL}/rest/v1/${t}?select=count`, {
                    headers: { 'apikey': ANON_KEY, 'Authorization': `Bearer ${ANON_KEY}`, 'Prefer': 'count=exact' }
                });
                console.log(`Table ${t}: count ${res.headers['content-range']}`);
            } catch (e) {
                console.log(`Table ${t}: missing or error`);
            }
        }
    } catch (e) {
        console.error('Error:', e.message);
    }
}

main();
