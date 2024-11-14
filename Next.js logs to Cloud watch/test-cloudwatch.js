const logger = require('./logger');

async function testCloudWatchConnection() {
  console.log('Starting CloudWatch test...');
  
  try {
    // Test different log levels
    logger.debug('Debug message', { test: 'debug logging' });
    logger.info('Info message', { test: 'info logging' });
    logger.warn('Warning message', { test: 'warning logging' });
    logger.error('Error message', { test: 'error logging' });

    // Test structured logging
    logger.info('Structured log test', {
      userId: 123,
      action: 'test',
      timestamp: new Date().toISOString()
    });

    console.log('Waiting for logs to be sent (10 seconds)...');
    // Wait longer to ensure logs are sent
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    console.log('Test completed. Check CloudWatch logs.');
  } catch (error) {
    console.error('Test failed:', error);
    console.error('Error stack:', error.stack);
  } finally {
    // Force the process to exit after another brief delay
    setTimeout(() => {
      console.log('Exiting process...');
      process.exit(0);
    }, 2000);
  }
}

// Handle any uncaught errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

testCloudWatchConnection();