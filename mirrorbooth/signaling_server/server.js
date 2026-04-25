const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, { cors: { origin: '*' } });

// rooms: Map<roomId, Set<socketId>>
const rooms = new Map();

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

io.on('connection', (socket) => {
  console.log('connected:', socket.id);

  socket.on('join_room', ({ roomId, userId }) => {
    if (!rooms.has(roomId)) rooms.set(roomId, new Map());
    const room = rooms.get(roomId);

    if (room.size >= 2) {
      socket.emit('error', { message: 'Room is full' });
      return;
    }

    room.set(socket.id, userId);
    socket.join(roomId);
    socket.data.roomId = roomId;

    // Notify other peer
    socket.to(roomId).emit('peer_joined', { peerId: socket.id });
    console.log(`${socket.id} joined room ${roomId} (size=${room.size})`);
  });

  socket.on('offer', ({ targetId, sdp }) => {
    io.to(targetId).emit('offer', { fromId: socket.id, sdp });
  });

  socket.on('answer', ({ targetId, sdp }) => {
    io.to(targetId).emit('answer', { fromId: socket.id, sdp });
  });

  socket.on('ice', ({ targetId, candidate }) => {
    io.to(targetId).emit('ice', { fromId: socket.id, candidate });
  });

  socket.on('leave_room', ({ roomId }) => {
    _leaveRoom(socket, roomId);
  });

  socket.on('disconnect', () => {
    if (socket.data.roomId) _leaveRoom(socket, socket.data.roomId);
    console.log('disconnected:', socket.id);
  });
});

function _leaveRoom(socket, roomId) {
  const room = rooms.get(roomId);
  if (!room) return;
  room.delete(socket.id);
  socket.to(roomId).emit('peer_left', { peerId: socket.id });
  socket.leave(roomId);
  if (room.size === 0) rooms.delete(roomId);
}

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => console.log(`Signaling server running on :${PORT}`));
