const express = require('express');
const router = express.Router();
const { createZoomMeeting,getZoomMeetings,getZoomRecordings , getZoomParticipants} = require('../controller/ZoomController');

router.get('/create-meeting', createZoomMeeting);
router.get('/get-meetings', getZoomMeetings);
router.get('/get-recordings', getZoomRecordings);
router.get('/get-participants/:meetingId',getZoomParticipants);


module.exports = router;
