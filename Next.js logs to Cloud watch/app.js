const readline = require('readline');
const logger = require('./logger');  // Import the logger

// Create an interface for input and output
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Function to perform calculation
function calculate(expression) {
  // Log the calculation attempt
  logger.info('Calculation attempted', { 
    expression,
    timestamp: new Date().toISOString()
  });

  try {
    // Evaluate the expression
    let result = eval(expression);

    // If the result is not a number, throw an error
    if (isNaN(result)) {
      logger.error('Invalid expression - Result is NaN', { 
        expression,
        timestamp: new Date().toISOString()
      });
      console.log('Error: Invalid Expression');
    } else {
      // Log successful calculation
      logger.info('Calculation successful', { 
        expression,
        result,
        timestamp: new Date().toISOString()
      });
      console.log('Result:', result);
    }
  } catch (error) {
    // Log calculation error
    logger.error('Calculation failed', { 
      expression,
      error: error.message,
      errorStack: error.stack,
      timestamp: new Date().toISOString()
    });
    console.log('Error: Invalid Expression');
  }
}

// Log application start
logger.info('Calculator application started', {
  timestamp: new Date().toISOString(),
  nodeVersion: process.version
});

// Ask user for a mathematical expression
rl.question('Enter a mathematical expression: ', (expression) => {
  // Log user input received
  logger.info('User input received', { 
    expression,
    timestamp: new Date().toISOString()
  });

  // Call calculate function to process the input expression
  calculate(expression);
  
  // Give CloudWatch transport time to send logs before closing
  setTimeout(() => {
    rl.close();
    // Log application exit
    logger.info('Calculator application closing', {
      timestamp: new Date().toISOString()
    });
    
    // Give additional time for final logs to be sent
    setTimeout(() => {
      process.exit(0);
    }, 1000);
  }, 1000);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception in calculator', { 
    error: error.message,
    stack: error.stack,
    timestamp: new Date().toISOString()
  });
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection in calculator', { 
    reason,
    timestamp: new Date().toISOString()
  });
});