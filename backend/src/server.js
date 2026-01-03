const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const socketHandler = require('./socket');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'HP House Signaling Server'
  });
});

// API info endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'HP House Signaling Server',
    version: '1.0.0',
    description: 'WebRTC signaling server for HP House audio/video rooms',
    endpoints: {
      health: '/health',
      socket: 'ws://localhost:3000'
    }
  });
});

// Create HTTP server
const httpServer = createServer(app);

// Create Socket.IO server
const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  transports: ['websocket', 'polling']
});

// Initialize socket handlers
socketHandler(io);

module.exports = httpServer;
