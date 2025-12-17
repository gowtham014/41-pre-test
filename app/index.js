const express = require('express');
const serverless = require('serverless-http');

const app = express();

// Required to get real client IP behind proxies (Lambda, API Gateway, LB, etc.)
app.set('trust proxy', true);

app.get('/', (req, res) => {
  let ip = req.ip || '';

  // Convert IPv4-mapped IPv6 to plain IPv4
  ip = ip.replace(/^::ffff:/, '');

  res.json({
    timestamp: new Date().toISOString(),
    ip: ip
  });
});

// Run locally / Docker
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`App running on port ${PORT}`);
  });
}
// Run on AWS Lambda / Serverless
else {
  module.exports.handler = serverless(app);
}
