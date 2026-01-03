const roomHandler = require('./roomHandler');
const signalingHandler = require('./signalingHandler');

// Store connected users and rooms
const connectedUsers = new Map();
const rooms = new Map();

module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log(`[Connect] User connected: ${socket.id}`);

    // Get user info from auth
    const odiumId = socket.handshake.auth?.userId;
    if (odiumId) {
      connectedUsers.set(socket.id, {
        odiumId: odiumId,
        socketId: socket.id,
        rooms: new Set()
      });
    }

    // Initialize handlers
    roomHandler(io, socket, connectedUsers, rooms);
    signalingHandler(io, socket, connectedUsers, rooms);

    // Handle disconnection
    socket.on('disconnect', (reason) => {
      console.log(`[Disconnect] User disconnected: ${socket.id}, Reason: ${reason}`);

      const user = connectedUsers.get(socket.id);
      if (user) {
        // Leave all rooms
        user.rooms.forEach(roomId => {
          socket.to(roomId).emit('user-left', {
            odiumId: user.odiumId,
            socketId: socket.id
          });

          // Remove from room participants
          const room = rooms.get(roomId);
          if (room) {
            room.participants.delete(socket.id);
            if (room.participants.size === 0) {
              rooms.delete(roomId);
              console.log(`[Room] Room ${roomId} deleted (empty)`);
            }
          }
        });

        connectedUsers.delete(socket.id);
      }
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error(`[Error] Socket error for ${socket.id}:`, error);
    });
  });

  // Log connection stats periodically
  setInterval(() => {
    console.log(`[Stats] Connected users: ${connectedUsers.size}, Active rooms: ${rooms.size}`);
  }, 60000);
};
