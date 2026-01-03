require('dotenv').config();
const server = require('./server');

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════╗
  ║   HP House Signaling Server Started       ║
  ║   Port: ${PORT}                               ║
  ║   Environment: ${process.env.NODE_ENV || 'development'}              ║
  ╚═══════════════════════════════════════════╝
  `);
});
