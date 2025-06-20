const mongoose = require('mongoose');

const tokenSchema = new mongoose.Schema({
  userId: { type: String, unique: true, required: true },
  accessToken: String,
  refreshToken: String,
  expiresAt: Date,
});

module.exports = mongoose.model('Token', tokenSchema);
