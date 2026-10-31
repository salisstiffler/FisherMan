const jwt = require('jsonwebtoken');
const db = require('../db');

const JWT_SECRET = process.env.JWT_SECRET || 'fisherman_secret_key_2026_super_secure';

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ code: 401, message: '请先登录以继续' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(decoded.id);
    if (!user) {
      return res.status(401).json({ code: 401, message: '用户不存在或已被删除' });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ code: 401, message: '登录状态已失效，请重新登录' });
  }
}

function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const user = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(decoded.id);
      if (user) {
        req.user = user;
      }
    } catch {
      // ignore expired optional tokens
    }
  }
  next();
}

function generateToken(user) {
  return jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '7d' });
}

function generateRefreshToken(user) {
  return jwt.sign({ id: user.id, username: user.username, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
}

function verifyRefreshToken(token) {
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.type !== 'refresh') return null;
    return decoded;
  } catch {
    return null;
  }
}

module.exports = {
  authenticate,
  optionalAuth,
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
  JWT_SECRET,
};
