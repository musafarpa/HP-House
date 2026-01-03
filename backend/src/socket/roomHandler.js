module.exports = (io, socket, connectedUsers, rooms) => {
  // Join room
  socket.on('join-room', (data) => {
    const { roomId, odiumId, userName, avatarUrl, hasVideo, hasAudio } = data;

    console.log(`[Room] User ${odiumId} joining room ${roomId}`);

    // Join socket room
    socket.join(roomId);

    // Update user's room list
    const user = connectedUsers.get(socket.id);
    if (user) {
      user.rooms.add(roomId);
    }

    // Create room if doesn't exist
    if (!rooms.has(roomId)) {
      rooms.set(roomId, {
        id: roomId,
        participants: new Map(),
        createdAt: new Date()
      });
    }

    // Add user to room participants
    const room = rooms.get(roomId);
    room.participants.set(socket.id, {
      odiumId,
      userName,
      avatarUrl,
      socketId: socket.id,
      hasVideo: hasVideo || false,
      hasAudio: hasAudio || false,
      isMuted: true,
      joinedAt: new Date()
    });

    // Get existing participants (excluding the new user)
    const existingParticipants = [];
    room.participants.forEach((participant, socketId) => {
      if (socketId !== socket.id) {
        existingParticipants.push(participant);
      }
    });

    // Send existing participants to the new user
    socket.emit('room-participants', {
      roomId,
      participants: existingParticipants
    });

    // Notify others that a new user joined
    socket.to(roomId).emit('user-joined', {
      odiumId,
      userName,
      avatarUrl,
      socketId: socket.id,
      hasVideo,
      hasAudio
    });

    console.log(`[Room] Room ${roomId} now has ${room.participants.size} participants`);
  });

  // Leave room
  socket.on('leave-room', (data) => {
    const { roomId } = data;
    const user = connectedUsers.get(socket.id);

    console.log(`[Room] User leaving room ${roomId}`);

    // Leave socket room
    socket.leave(roomId);

    // Update user's room list
    if (user) {
      user.rooms.delete(roomId);
    }

    // Remove from room participants
    const room = rooms.get(roomId);
    if (room) {
      const participant = room.participants.get(socket.id);
      room.participants.delete(socket.id);

      // Notify others
      socket.to(roomId).emit('user-left', {
        odiumId: participant?.odiumId || user?.odiumId,
        socketId: socket.id
      });

      // Delete room if empty
      if (room.participants.size === 0) {
        rooms.delete(roomId);
        console.log(`[Room] Room ${roomId} deleted (empty)`);
      }
    }
  });

  // Toggle audio
  socket.on('toggle-audio', (data) => {
    const { roomId, isMuted } = data;

    // Update participant state
    const room = rooms.get(roomId);
    if (room) {
      const participant = room.participants.get(socket.id);
      if (participant) {
        participant.isMuted = isMuted;
      }
    }

    // Notify others
    socket.to(roomId).emit('user-toggled-audio', {
      socketId: socket.id,
      odiumId: connectedUsers.get(socket.id)?.odiumId,
      isMuted
    });
  });

  // Toggle video
  socket.on('toggle-video', (data) => {
    const { roomId, isEnabled } = data;

    // Update participant state
    const room = rooms.get(roomId);
    if (room) {
      const participant = room.participants.get(socket.id);
      if (participant) {
        participant.hasVideo = isEnabled;
      }
    }

    // Notify others
    socket.to(roomId).emit('user-toggled-video', {
      socketId: socket.id,
      odiumId: connectedUsers.get(socket.id)?.odiumId,
      isEnabled
    });
  });

  // Raise hand
  socket.on('raise-hand', (data) => {
    const { roomId } = data;
    const user = connectedUsers.get(socket.id);

    socket.to(roomId).emit('hand-raised', {
      socketId: socket.id,
      odiumId: user?.odiumId
    });
  });

  // Chat message (in-room chat)
  socket.on('chat-message', (data) => {
    const { roomId, message } = data;
    const user = connectedUsers.get(socket.id);

    io.to(roomId).emit('new-message', {
      socketId: socket.id,
      odiumId: user?.odiumId,
      message,
      timestamp: new Date().toISOString()
    });
  });
};
