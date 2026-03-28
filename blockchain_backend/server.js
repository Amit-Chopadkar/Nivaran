require('dotenv').config();
const express = require('express');
const ethers = require('ethers');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const turf = require('@turf/turf');
const axios = require('axios');
const polyline = require('@mapbox/polyline');
const multer = require('multer');

if (!fs.existsSync(path.join(__dirname, 'uploads'))) {
    fs.mkdirSync(path.join(__dirname, 'uploads'));
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads'))
  },
  filename: function (req, file, cb) {
    // We expect the log id in the body to use as the filename
    const logId = req.body.logId || 'unknown_sos';
    cb(null, logId + '.m4a')
  }
});

const upload = multer({ storage: storage });

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_safeher';
// Persistent db for testing (wallet_address -> user object, nonce etc)
const DB_FILE = path.join(__dirname, 'usersDB.json');
let usersDB = new Map();
if (fs.existsSync(DB_FILE)) {
    try {
        const data = fs.readFileSync(DB_FILE, 'utf8');
        usersDB = new Map(Object.entries(JSON.parse(data)));
    } catch (e) {
        console.error('Error loading usersDB.json:', e);
    }
}

function saveDB() {
    try {
        fs.writeFileSync(DB_FILE, JSON.stringify(Object.fromEntries(usersDB)), 'utf8');
    } catch (e) {
        console.error('Error saving usersDB.json:', e);
    }
}

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Load Contract ABI and Address
let contractABI;
let contractAddress = process.env.CONTRACT_ADDRESS;

try {
    const contractData = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'blockchain', 'build', 'TrustVerify.json'), 'utf8'));
    contractABI = contractData.abi;
} catch (error) {
    console.error("Error loading contract ABI. Make sure to run compile.js first.");
}

// Blockchain Setup
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'https://rpc-amoy.polygon.technology');
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || '0x0000000000000000000000000000000000000000000000000000000000000001', provider);
let contract;

if (contractAddress && contractABI) {
    contract = new ethers.Contract(contractAddress, contractABI, wallet);
}

// Hashing Helper
function generateHash(data) {
    return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
}

// --- Auth & Identity Routes ---
app.post('/api/auth/signup', (req, res) => {
    try {
        console.log('--- /api/auth/signup called ---', req.body);
        const { wallet_address, name, phone, email } = req.body;
        if (!wallet_address) return res.status(400).json({ error: 'wallet_address is required' });
        
        const address = wallet_address.toLowerCase();
        
        // 1. Check if this wallet is already registered to SAME email (redundant but safe)
        if (usersDB.has(address)) {
            const existingUser = usersDB.get(address);
            if (existingUser.email === email) {
                console.log('User already registered with this wallet and email.');
                return res.json({ success: true, user: existingUser, message: 'Existing profile re-synced' });
            }
        }

        // 2. Allow re-registering with same email but NEW wallet (Device migration)
        let foundUser = null;
        for (let user of usersDB.values()) {
            if (user.email === email) {
                foundUser = user;
                break;
            }
        }

        if (foundUser) {
            console.log(`Found existing user with email ${email}. Updating wallet to ${address}`);
            // Remove old mapping if wallet changed
            if (foundUser.wallet_address !== address) {
                usersDB.delete(foundUser.wallet_address);
            }
            
            foundUser.wallet_address = address;
            foundUser.name = name || foundUser.name;
            foundUser.phone = phone || foundUser.phone;
            foundUser.nonce = uuidv4();
            
            usersDB.set(address, foundUser);
            saveDB();
            return res.json({ success: true, user: foundUser, message: 'Wallet updated' });
        }

        // 3. Brand new user
        const newUser = {
            wallet_address: address,
            name,
            phone,
            email,
            nonce: uuidv4(),
            created_at: new Date().toISOString()
        };
        usersDB.set(address, newUser);
        saveDB();
        
        console.log(`Successfully registered new user: ${email} with wallet ${address}`);
        res.json({ success: true, user: newUser });
    } catch (e) {
        console.error('Signup error stack:', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

app.post('/api/auth/nonce', (req, res) => {
    try {
        console.log('--- /api/auth/nonce called ---', req.body);
        const { wallet_address } = req.body;
        const address = wallet_address?.toLowerCase();
        
        if (!address || !usersDB.has(address)) {
            console.log('User not found during nonce request for address:', wallet_address);
            return res.status(404).json({ error: 'User not found in usersDB. Have you signed up yet?' });
        }

        // Generate a new nonce
        const user = usersDB.get(address);
        user.nonce = uuidv4();
        usersDB.set(address, user);
        saveDB();

        res.json({ success: true, nonce: user.nonce });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

app.post('/api/auth/verify', (req, res) => {
    try {
        console.log('--- /api/auth/verify called ---', req.body);
        const { wallet_address, signature } = req.body;
        const address = wallet_address?.toLowerCase();

        if (!address || !usersDB.has(address)) {
            console.log('User not found during verify request for address:', address);
            return res.status(404).json({ error: 'User not found' });
        }

        const user = usersDB.get(address);
        const expectedNonce = user.nonce;

        // Verify signature using ethers
        const recoveredAddress = ethers.verifyMessage(expectedNonce, signature);
        
        if (recoveredAddress.toLowerCase() !== address) {
            return res.status(401).json({ error: 'Invalid signature' });
        }

        // Generate new nonce to prevent replay attacks
        user.nonce = uuidv4();
        usersDB.set(address, user);
        saveDB();

        // Issue JWT token
        const token = jwt.sign(
            { wallet_address: address, sub: address }, 
            JWT_SECRET, 
            { expiresIn: '30d' }
        );

        res.json({ success: true, token, user });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// --- Blockchain Event Routes ---
app.post('/api/blockchain/kyc', async (req, res) => {
    try {
        const userData = req.body;
        // 1. Generate SHA256 Hash
        const hash = generateHash(userData);
        
        console.log(`Generating KYC hash: ${hash}`);

        // 2. Add to Blockchain if contract is deployed
        if (contract) {
            const tx = await contract.storeKYC(hash);
            await tx.wait();
            return res.json({
                success: true,
                hash: hash,
                txHash: tx.hash,
                message: "KYC hash stored on blockchain"
            });
        } else {
            return res.json({
                success: true,
                hash: hash,
                txHash: "0xMockTxHash_" + Date.now(),
                message: "KYC hash generated (Blockchain contract not deployed yet)"
            });
        }
    } catch (error) {
        console.error("KYC Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/blockchain/sos', async (req, res) => {
    try {
        const sosData = req.body;
        // 1. Generate SHA256 Hash
        const hash = generateHash(sosData);
        
        console.log(`Generating SOS hash: ${hash}`);

        // 2. Add to Blockchain if contract is deployed
        if (contract) {
            const tx = await contract.storeSOS(hash);
            await tx.wait();
            return res.json({
                success: true,
                hash: hash,
                txHash: tx.hash,
                message: "SOS log stored on blockchain"
            });
        } else {
            return res.json({
                success: true,
                hash: hash,
                txHash: "0xMockTxHash_" + Date.now(),
                message: "SOS hash generated (Blockchain contract not deployed yet)"
            });
        }
    } catch (error) {
        console.error("SOS Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/blockchain/sos/audio', upload.single('audio'), (req, res) => {
    try {
        console.log('Received audio for SOS log:', req.body.logId);
        res.json({ success: true, message: 'Audio uploaded successfully' });
    } catch (e) {
        console.error('Audio upload error:', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

app.get('/api/blockchain/sos-logs', async (req, res) => {
    try {
        if (contract) {
            const logs = await contract.getSOSLogs();
            res.json({ success: true, logs });
        } else {
            res.json({ success: true, logs: ["Mock SOS Hash 1", "Mock SOS Hash 2"] });
        }
    } catch (error) {
        console.error("SOS Logs Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// --- Safest Route Logic ---
const GRAPHHOPPER_API_KEY = process.env.GRAPHHOPPER_API_KEY;

app.post('/api/routes/safest', async (req, res) => {
    try {
        const { origin, destination } = req.body;
        console.log(`\n🚀 [ROUTE] Calculating path: "${origin}" → "${destination}"`);

        if (!GRAPHHOPPER_API_KEY) {
            console.error('❌ [ERROR] GRAPHHOPPER_API_KEY is missing from environment variables!');
            return res.status(500).json({ success: false, error: 'Routing service configuration missing (API Key)' });
        }

        // --- Parse lat,lng string ---
        const parseLatLng = (str) => {
            const [lat, lng] = str.split(',').map(s => parseFloat(s.trim()));
            return { lat, lng };
        };

        // --- Geocode a place name via Nominatim ---
        const geocode = async (placeName) => {
            const cleanName = placeName.trim();
            console.log(`🔍 Geocoding: "${cleanName}"`);
            const geoRes = await axios.get('https://nominatim.openstreetmap.org/search', {
                params: { q: `${cleanName}, Nashik, India`, format: 'json', limit: 1 },
                headers: { 'User-Agent': 'SafeHerApp/1.0' }
            });
            if (!geoRes.data?.length) {
                // Fallback without strict Nashik restriction
                const geoFallback = await axios.get('https://nominatim.openstreetmap.org/search', {
                    params: { q: cleanName, format: 'json', limit: 1 },
                    headers: { 'User-Agent': 'SafeHerApp/1.0' }
                });
                if (!geoFallback.data?.length) throw new Error(`Geocoding failed for "${cleanName}"`);
                const { lat, lon } = geoFallback.data[0];
                return { lat: parseFloat(lat), lng: parseFloat(lon) };
            }
            const { lat, lon } = geoRes.data[0];
            console.log(`✅ Geocoded "${cleanName}" → [${lat},${lon}]`);
            return { lat: parseFloat(lat), lng: parseFloat(lon) };
        };

        // --- Resolve origin & destination ---
        const isLatLng = (s) => /^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$/.test(s.trim());
        
        let orig, dest;
        try {
            orig = isLatLng(origin)      ? parseLatLng(origin)      : await geocode(origin);
            dest = isLatLng(destination) ? parseLatLng(destination) : await geocode(destination);
            console.log(`✅ [GEO] Resolved: [${orig.lat},${orig.lng}] → [${dest.lat},${dest.lng}]`);
        } catch (geoErr) {
            console.error(`❌ [ERROR] Geocoding failure: ${geoErr.message}`);
            return res.status(400).json({ success: false, error: `Geocoding failed: ${geoErr.message}` });
        }

        // --- Call GraphHopper Routing API ---
        console.log(`🗺️  GraphHopper: [${orig.lat},${orig.lng}] → [${dest.lat},${dest.lng}]`);
        
        const searchParams = new URLSearchParams();
        searchParams.append('point', `${orig.lat},${orig.lng}`);
        searchParams.append('point', `${dest.lat},${dest.lng}`);
        searchParams.append('vehicle', 'car');
        searchParams.append('points_encoded', 'false');
        searchParams.append('instructions', 'true');
        searchParams.append('locale', 'en');
        searchParams.append('algorithm', 'alternative_route');
        searchParams.append('alternative_route.max_paths', '3');
        searchParams.append('key', GRAPHHOPPER_API_KEY);
        
        const ghRes = await axios.get(`https://graphhopper.com/api/1/route?${searchParams.toString()}`, {
            timeout: 15000
        });

        if (!ghRes.data?.paths || ghRes.data.paths.length === 0) {
            console.warn('⚠️ [GH] No paths found by GraphHopper');
            return res.status(404).json({ success: false, error: 'No routes found between these points' });
        }

        const paths = ghRes.data.paths;
        console.log(`✅ [GH] Received ${paths.length} route(s). Processing safety analysis...`);

        // --- Analyse each path for safety ---
        const analyzed = paths.map((path, index) => {
            const coords  = path.points.coordinates; // [[lng, lat], ...]
            const geoJson = { type: 'LineString', coordinates: coords };
            let safetyScore = 0;
            redZonePolygons.forEach(poly => {
                if (turf.booleanIntersects(geoJson, poly)) safetyScore++;
            });
            return {
                index,
                summary:     path.description || `Route ${index + 1}`,
                safetyScore,
                isSafe:      safetyScore === 0,
                distanceKm:  (path.distance / 1000).toFixed(1),
                durationMin: Math.round(path.time / 60000),
                // Flutter needs { latitude, longitude }
                path: coords.map(c => ({ latitude: c[1], longitude: c[0] })),
                instructions: (path.instructions || []).map(step => ({
                    instruction: step.text,
                    distance:    step.distance < 1000
                                    ? `${Math.round(step.distance)}m`
                                    : `${(step.distance / 1000).toFixed(1)}km`,
                    isSafeZone:  true,
                })),
            };
        });

        // --- Select safest route ---
        analyzed.sort((a, b) => a.safetyScore - b.safetyScore);
        const safest = analyzed[0];
        console.log(`✅ Safest: ${safest.path.length} pts, score ${safest.safetyScore}, ${safest.distanceKm}km, ${safest.durationMin}min`);

        res.json({
            success:           true,
            source:            'GraphHopper',
            safestRoute:       safest,
            status:            safest.isSafe ? 'Safe' : 'Risky',
            alternativeRoutes: analyzed.slice(1),
        });

    } catch (error) {
        const errorDetail = error.response?.data || error.message;
        console.error('❌ [ROUTE ERROR]:', errorDetail);
        
        const displayMsg = typeof errorDetail === 'object' 
            ? (errorDetail.message || JSON.stringify(errorDetail)) 
            : errorDetail;
            
        res.status(500).json({ success: false, error: displayMsg });
    }
});
const crimeHotspots = [
  { lat: 19.9975, lng: 73.7898, intensity: 0.8, type: 'Theft', area: 'College Road' },
  { lat: 20.0059, lng: 73.7654, intensity: 0.7, type: 'Harassment', area: 'Gangapur Road' },
  { lat: 19.9950, lng: 73.7860, intensity: 0.9, type: 'Assault', area: 'CBS' },
  { lat: 20.0110, lng: 73.7900, intensity: 0.6, type: 'Stalking', area: 'Panchavati' },
  { lat: 19.9600, lng: 73.8300, intensity: 0.85, type: 'Robbery', area: 'Nashik Road' },
  { lat: 19.9900, lng: 73.8000, intensity: 0.75, type: 'Chain Snatching', area: 'Dwarka' },
  { lat: 19.9700, lng: 73.7700, intensity: 0.7, type: 'Theft', area: 'Indira Nagar' },
  { lat: 19.9905, lng: 73.7300, intensity: 0.8, type: 'Assault', area: 'Satpur MIDC' },
  { lat: 19.9500, lng: 73.7500, intensity: 0.75, type: 'Harassment', area: 'Ambad MIDC' },
  { lat: 20.0200, lng: 73.7800, intensity: 0.65, type: 'Suspicious Activity', area: 'Makhmalabad Road' },
  { lat: 19.9500, lng: 73.7800, intensity: 0.7, type: 'Theft', area: 'Pathardi Phata' },
  { lat: 20.0300, lng: 73.8000, intensity: 0.6, type: 'Harassment', area: 'Adgaon' },
  { lat: 19.9800, lng: 73.7700, intensity: 0.7, type: 'Robbery', area: 'Trimurti Chowk' },
  { lat: 19.9955, lng: 73.7805, intensity: 0.85, type: 'Theft', area: 'Canada Corner' },
  { lat: 19.9980, lng: 73.7850, intensity: 0.75, type: 'Assault', area: 'Shalimar' },
  { lat: 19.9400, lng: 73.8500, intensity: 0.6, type: 'Stalking', area: 'Deolali Camp' },
  { lat: 20.1000, lng: 73.9000, intensity: 0.55, type: 'Theft', area: 'Ojhar' },
  { lat: 19.7000, lng: 73.5500, intensity: 0.5, type: 'Harassment', area: 'Igatpuri' },
];

// Convert hotspots to buffered polygons (Red Zones)
const redZonePolygons = crimeHotspots.map(spot => {
    const pt = turf.point([spot.lng, spot.lat]);
    return turf.buffer(pt, 0.4, { units: 'kilometers' }); // 400m danger radius
});


app.listen(PORT, '0.0.0.0', () => {
    console.log(`Blockchain Backend running on http://0.0.0.0:${PORT}`);
});
