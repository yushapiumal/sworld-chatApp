require('dotenv').config();
const express = require('express');
const cors = require('cors');
const os = require('os');
const zoomRoutes = require('./router/ZoomRouter');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/', zoomRoutes);

// Function to get local IP address
function getLocalIPAddress() {
  const interfaces = os.networkInterfaces();
  for (const interfaceName in interfaces) {
    const addresses = interfaces[interfaceName];
    for (const addr of addresses) {
      if (addr.family === 'IPv4' && !addr.internal) {
        return addr.address;
      }
    }
  }
  return 'localhost';
}

app.listen(PORT, () => {
  const ip = getLocalIPAddress();
  console.log(`Server running on:`);
  console.log(` → http://localhost:${PORT}`);
  console.log(` → http://${ip}:${PORT}`);
});
