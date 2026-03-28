const axios = require('axios');

const SUPA_URL = 'https://runvwdnilflwjhywgdxo.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1bnZ3ZG5pbGZsd2poeXdnZHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODU0NjYsImV4cCI6MjA4OTY2MTQ2Nn0.MCLbGhg4FGAi2Y1O4gl_U5HzqZcjzUhHjZWRGoQuAzA';

async function main() {
    try {
        const res = await axios.get(`${SUPA_URL}/rest/v1/incidents?select=*`, {
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`
            }
        });
        console.log('Incidents count:', res.data.length);
        console.log('First incident:', JSON.stringify(res.data[0], null, 2));
    } catch (e) {
        console.error('Error fetching incidents:', e.response?.data || e.message);
    }
}

main();
