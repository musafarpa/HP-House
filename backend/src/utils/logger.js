const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

const getTimestamp = () => {
  return new Date().toISOString();
};

const logger = {
  info: (message, ...args) => {
    console.log(
      `${colors.cyan}[INFO]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} ${message}`,
      ...args
    );
  },

  success: (message, ...args) => {
    console.log(
      `${colors.green}[SUCCESS]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} ${message}`,
      ...args
    );
  },

  warn: (message, ...args) => {
    console.log(
      `${colors.yellow}[WARN]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} ${message}`,
      ...args
    );
  },

  error: (message, ...args) => {
    console.error(
      `${colors.red}[ERROR]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} ${message}`,
      ...args
    );
  },

  debug: (message, ...args) => {
    if (process.env.NODE_ENV === 'development') {
      console.log(
        `${colors.magenta}[DEBUG]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} ${message}`,
        ...args
      );
    }
  },

  socket: (event, message, ...args) => {
    console.log(
      `${colors.blue}[SOCKET]${colors.reset} ${colors.dim}${getTimestamp()}${colors.reset} [${event}] ${message}`,
      ...args
    );
  }
};

module.exports = logger;
