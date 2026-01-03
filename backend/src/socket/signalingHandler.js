module.exports = (io, socket, connectedUsers, rooms) => {
  // WebRTC Offer
  socket.on('offer', (data) => {
    const { targetId, offer } = data;
    const user = connectedUsers.get(socket.id);

    console.log(`[WebRTC] Offer from ${socket.id} to ${targetId}`);

    // Find target socket
    const targetSocket = findSocketByUserId(connectedUsers, targetId) || targetId;

    io.to(targetSocket).emit('offer', {
      senderId: socket.id,
      senderUserId: user?.odiumId,
      offer
    });
  });

  // WebRTC Answer
  socket.on('answer', (data) => {
    const { targetId, answer } = data;
    const user = connectedUsers.get(socket.id);

    console.log(`[WebRTC] Answer from ${socket.id} to ${targetId}`);

    // Find target socket
    const targetSocket = findSocketByUserId(connectedUsers, targetId) || targetId;

    io.to(targetSocket).emit('answer', {
      senderId: socket.id,
      senderUserId: user?.odiumId,
      answer
    });
  });

  // ICE Candidate
  socket.on('ice-candidate', (data) => {
    const { targetId, candidate } = data;
    const user = connectedUsers.get(socket.id);

    // Find target socket
    const targetSocket = findSocketByUserId(connectedUsers, targetId) || targetId;

    io.to(targetSocket).emit('ice-candidate', {
      senderId: socket.id,
      senderUserId: user?.odiumId,
      candidate
    });
  });

  // Request to connect with specific user
  socket.on('request-connection', (data) => {
    const { targetId, roomId } = data;
    const user = connectedUsers.get(socket.id);

    console.log(`[WebRTC] Connection request from ${socket.id} to ${targetId}`);

    // Find target socket
    const targetSocket = findSocketByUserId(connectedUsers, targetId) || targetId;

    io.to(targetSocket).emit('connection-request', {
      senderId: socket.id,
      senderUserId: user?.odiumId,
      roomId
    });
  });
};

// Helper function to find socket ID by user ID
function findSocketByUserId(connectedUsers, odiumId) {
  for (const [socketId, user] of connectedUsers) {
    if (user.odiumId === odiumId) {
      return socketId;
    }
  }
  return null;
}
