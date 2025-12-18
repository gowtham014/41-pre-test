const express = require('express');
const serverless = require('serverless-http');

/**
 * Create Express App
 */
function createApp() {
  const app = express();

  app.set('trust proxy', true);
  app.use(express.json());

  // Health check
  app.get('/health', (req, res) => {
    res.status(200).send('OK');
  });

  // Main route
  app.get('/', (req, res) => {
    const forwarded = req.headers['x-forwarded-for'];
    let ip = forwarded ? forwarded.split(',')[0] : req.ip || '';

    ip = ip.replace(/^::ffff:/, '');

    res.json({
      timestamp: new Date().toISOString(),
      ip: ip
    });
  });

  return app;
}

const app = createApp();

/**
 * ECS / CONTAINER MODE
 */
if (require.main === module) {
  const PORT = process.env.PORT || 3000;

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });

  process.on('SIGTERM', () => {
    console.log('SIGTERM received');
    process.exit(0);
  });
}

/**
 * AWS LAMBDA MODE
 */
module.exports.handler = serverless(app);
