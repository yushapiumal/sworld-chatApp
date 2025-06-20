const axios = require('axios');
const qs = require('qs');

async function getZoomAccessToken() {
  const res = await axios.post(
    'https://zoom.us/oauth/token',
    qs.stringify({
      grant_type: 'account_credentials',
      account_id: process.env.ACCOUNT_ID,
    }),
    {
      auth: {
        username: process.env.CLIENT_ID,
        password: process.env.CLIENT_SECRET,
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }
  );
  return res.data.access_token;
}

exports.createZoomMeeting = async (req, res) => {
  try {
    const token = await getZoomAccessToken();
    const meeting = await axios.post(
      'https://api.zoom.us/v2/users/me/meetings',
      {
        topic: 'Flutter Demo Meeting',
        type: 1,
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ join_url: meeting.data.join_url });
  } catch (err) {
    console.error(err.response?.data || err);
    res.status(500).json({ error: 'Failed to create meeting' });
  }
};


exports.getZoomMeetings = async (req, res) => {
  try {
    const token = await getZoomAccessToken();
    const response = await axios.get(
      'https://api.zoom.us/v2/users/me/meetings',
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );
    res.json({ meetings: response.data.meetings });
  } catch (err) {
    console.error(err.response?.data || err);
    res.status(500).json({ error: 'Failed to fetch meetings' });
  }
};


exports.getZoomRecordings = async (req, res) => {
  try {
    const token = await getZoomAccessToken();
    const response = await axios.get(
      'https://api.zoom.us/v2/users/me/recordings',
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );
    res.json({ recordings: response.data.meetings });
  } catch (err) {
    console.error(err.response?.data || err);
    res.status(500).json({ error: 'Failed to fetch recordings' });
  }
};

exports.getZoomParticipants = async (req, res) => {
  const { meetingId } = req.params;
  try {
    const token = await getZoomAccessToken();
    const response = await axios.get(
      `https://api.zoom.us/v2/past_meetings/${meetingId}/participants`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );
    res.json({ participants: response.data.participants });
  } catch (err) {
    console.error(err.response?.data || err);
    res.status(500).json({ error: 'Failed to fetch participants' });
  }
};
