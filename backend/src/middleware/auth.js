const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Invalid token format' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Socket authentication middleware
const socketAuth = async (socket, next) => {
  const token = socket.handshake.auth?.token;
  const odiumId = socket.handshake.auth?.odiumId;

  // For development, allow connection without token
  if (process.env.NODE_ENV === 'development' && odiumId) {
    socket.odiumId = odiumId;
    return next();
  }

  if (!token) {
    return next(new Error('Authentication required'));
  }

  try {
    // Verify with Supabase if available
    if (supabase) {
      const { data: { user }, error } = await supabase.auth.getUser(token);

      if (error || !user) {
        return next(new Error('Invalid token'));
      }

      socket.odiumId = user.id;
    } else {
      // Fallback to JWT verification
      const decoded = jwt.verify(token, JWT_SECRET);
      socket.odiumId = decoded.sub || decoded.odiumId;
    }

    next();
  } catch (error) {
    next(new Error('Authentication failed'));
  }
};

module.exports = {
  verifyToken,
  socketAuth
};
