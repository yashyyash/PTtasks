const winston = require('winston');
const WinstonCloudWatch = require('winston-cloudwatch');
const AWS = require('aws-sdk');

// Enable debug logging for AWS SDK
const aws_sdk_debug = require('aws-sdk/lib/config');
aws_sdk_debug.logger = console;

// AWS Configuration with debug logging
AWS.config.update({
  region: process.env.AWS_REGION,
  credentials: new AWS.Credentials({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }),
  logger: console
});

// Create CloudWatch transport with more detailed options
const cloudwatchTransport = new WinstonCloudWatch({
  logGroupName: 'calculator-app-logs',
  logStreamName: `calculator-${new Date().toISOString().split('T')[0]}`,
  awsRegion: process.env.AWS_REGION,
  messageFormatter: ({ level, message, ...meta }) => ({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...meta,
    application: 'calculator-app'
  }),
  uploadRate: 2000,
  createLogGroup: true,
  createLogStream: true,
  handleExceptions: true,
  jsonMessage: true,
  awsOptions: {
    logger: console,
    credentials: AWS.config.credentials,
    region: process.env.AWS_REGION,
    retryDelayOptions: { base: 200 }
  }
});

// Add detailed error handling for CloudWatch transport
cloudwatchTransport.on('error', (error) => {
  console.error('CloudWatch Transport Error:', error);
  console.error('Error Stack:', error.stack);
});

cloudwatchTransport.on('connect', () => {
  console.log('Successfully connected to CloudWatch');
});

// Create Winston logger with debug level
const logger = winston.createLogger({
  level: 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    }),
    cloudwatchTransport
  ],
  exceptionHandlers: [
    new winston.transports.Console({
      format: winston.format.simple()
    }),
    cloudwatchTransport
  ]
});

// Add some initialization logging
logger.info('Logger initialized', { 
  region: process.env.AWS_REGION,
  logGroup: 'calculator-app-logs',
  logStream: `calculator-${new Date().toISOString().split('T')[0]}`
});

module.exports = logger;