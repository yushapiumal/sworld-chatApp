require('dotenv').config();
const express = require('express');
const axios = require('axios');
const qs = require('qs');
const fs = require('fs');
const os = require('os');
const app = express();
app.use(express.json());



// === Persist Zoom tokens to file ===
function saveTokens(tokens) {
  fs.writeFileSync('./zoom_tokens.json', JSON.stringify(tokens, null, 2));
}

function loadTokens() {
  if (fs.existsSync('./zoom_tokens.json')) {
    return JSON.parse(fs.readFileSync('./zoom_tokens.json'));
  }
  return { access_token: null, refresh_token: null };
}

let zoomTokens = loadTokens();

// === 1) Get the Zoom OAuth authorization URL ===
app.get('/zoom/auth-url', (req, res) => {
  const authUrl = `https://zoom.us/oauth/authorize?response_type=code&client_id=${process.env.ZOOM_CLIENT_ID}&redirect_uri=${process.env.ZOOM_REDIRECT_URI}`;
  res.json({ url: authUrl });
});

// === 2) Handle Zoom OAuth callback ===
app.get('/zoom/callback', async (req, res) => {
  const authCode = req.query.code;

  if (!authCode) {
    return res.status(400).send('Missing authorization code.');
  }

  try {
    const response = await axios.post(
      'https://zoom.us/oauth/token',
      qs.stringify({
        grant_type: 'authorization_code',
        code: authCode,
        redirect_uri: process.env.ZOOM_REDIRECT_URI,
      }),
      {
        auth: {
          username: process.env.ZOOM_CLIENT_ID,
          password: process.env.ZOOM_CLIENT_SECRET,
        },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    zoomTokens = {
      access_token: response.data.access_token,
      refresh_token: response.data.refresh_token,
    };
    saveTokens(zoomTokens);

    console.log('✅ Zoom tokens saved:', zoomTokens);
    res.send('✅ Zoom authorization successful! You can close this window.');
  } catch (err) {
    console.error('❌ OAuth callback failed:', err.response?.data || err);
    res.status(500).send('OAuth callback failed.');
  }
});

// === 3) Validate & Refresh token if needed ===
async function getValidAccessToken() {
  if (!zoomTokens.access_token) throw new Error('Not authorized.');

  try {
    // Test the token by getting user info
    await axios.get('https://api.zoom.us/v2/users/me', {
      headers: { Authorization: `Bearer ${zoomTokens.access_token}` },
    });
    return zoomTokens.access_token;

  } catch (err) {
    console.log('⚠️ Access token expired, refreshing...');
    // Refresh the token
    const response = await axios.post(
      'https://zoom.us/oauth/token',
      qs.stringify({
        grant_type: 'refresh_token',
        refresh_token: zoomTokens.refresh_token,
      }),
      {
        auth: {
          username: process.env.ZOOM_CLIENT_ID,
          password: process.env.ZOOM_CLIENT_SECRET,
        },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    zoomTokens = {
      access_token: response.data.access_token,
      refresh_token: response.data.refresh_token,
    };
    saveTokens(zoomTokens);

    console.log('✅ Zoom tokens refreshed:', zoomTokens);
    return zoomTokens.access_token;
  }
}

// === 4) Create a meeting ===
app.post('/zoom/createMeeting', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    // Validate req.body
    const topic = req.body?.topic || 'My Zoom Meeting';

    const response = await axios.post(
      'https://api.zoom.us/v2/users/me/meetings',
      {
        topic,
        type: 2, // Scheduled meeting
        start_time: req.body.start_time || undefined,
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error('❌ Create Meeting failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to create meeting' });
  }
});

// === 5) List meetings ===
app.get('/zoom/listMeetings', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    const response = await axios.get(
      'https://api.zoom.us/v2/users/me/meetings',
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error('❌ List Meetings failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to list meetings' });
  }
});

// === 6) Get meeting details ===
app.get('/zoom/getMeeting/:id', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    const response = await axios.get(
      `https://api.zoom.us/v2/meetings/${req.params.id}`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error('❌ Get Meeting failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to get meeting details' });
  }
});

// === 7) Update meeting ===
app.patch('/zoom/updateMeeting/:id', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    const response = await axios.patch(
      `https://api.zoom.us/v2/meetings/${req.params.id}`,
      req.body,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    if (response.status === 204) {
      res.json({ message: `Meeting ${req.params.id} updated successfully` });
    } else {
      res.json(response.data); // Just in case Zoom changes it in the future
    }

  } catch (err) {
    console.error('❌ Update Meeting failed:', err.response?.data || err);
    res.status(500).json({
      error: 'Failed to update meeting',
      details: err.response?.data || err.message
    });
  }
});


// === 8) Delete meeting ===
app.delete('/zoom/deleteMeeting/:id', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    await axios.delete(
      `https://api.zoom.us/v2/meetings/${req.params.id}`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json({ message: 'Meeting deleted.' });
  } catch (err) {
    console.error('❌ Delete Meeting failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to delete meeting' });
  }
});

// === 9) Get participants for a past meeting ===
app.get('/zoom/getParticipants/:meetingId', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    const response = await axios.get(
      `https://api.zoom.us/v2/past_meetings/${req.params.meetingId}/participants`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error('❌ Get Participants failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to get participants' });
  }
});

// === 10) List recordings ===
app.get('/zoom/listRecordings', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    const response = await axios.get(
      'https://api.zoom.us/v2/users/me/recordings',
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error('❌ List Recordings failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to list recordings' });
  }
});

// === 11) Delete recording ===
app.delete('/zoom/deleteRecording/:recordingId', async (req, res) => {
  try {
    const token = await getValidAccessToken();

    await axios.delete(
      `https://api.zoom.us/v2/meetings/${req.params.recordingId}/recordings`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.json({ message: 'Recording deleted.' });
  } catch (err) {
    console.error('❌ Delete Recording failed:', err.response?.data || err);
    res.status(500).json({ error: 'Failed to delete recording' });
  }
});


function getLocalIPAddress() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip over internal (i.e. 127.0.0.1) and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost'; // fallback
}

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  const ip = getLocalIPAddress();
  console.log(`Server running on:`);
  console.log(` → http://localhost:${PORT}`);
  console.log(` → http://${ip}:${PORT}`);
});
