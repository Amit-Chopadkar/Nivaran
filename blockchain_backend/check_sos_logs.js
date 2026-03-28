const axios = require('axios');

const SUPA_URL = 'https://runvwdnilflwjhywgdxo.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1bnZ3ZG5pbGZsd2poeXdnZHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODU0NjYsImV4cCI6MjA4OTY2MTQ2Nn0.MCLbGhg4FGAi2Y1O4gl_U5HzqZcjzUhHjZWRGoQuAzA';

async function main() {
    try {
        const res = await axios.get(`${SUPA_URL}/storage/v1/bucket`, {
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`
            }
        });
        console.log('Buckets:', res.data.map(b => b.name));

        // Let's try to add the audio_url column using a hacky query if RLS allows it, but it likely won't.
        // I will just print the buckets to see if any are suitable for audio.
    } catch (e) {
        console.error('Error fetching buckets:', e.response?.data || e.message);
    }
}

main();
