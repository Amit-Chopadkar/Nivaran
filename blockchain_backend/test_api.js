const axios = require('axios');
axios.post('http://127.0.0.1:3000/api/routes/safest', {
    origin: '19.9975, 73.7898',
    destination: 'Nashik Road'
}).then(res => console.log(`SUCCESS [${res.data.source}]: ${res.data.safestRoute.path.length} pts, ${res.data.safestRoute.distanceKm}km, ${res.data.safestRoute.durationMin}min`))
  .catch(err => console.log('ERROR:', err.response?.data || err.message));
