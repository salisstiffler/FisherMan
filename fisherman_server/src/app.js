const express = require('express');
const cors = require('cors');
const path = require('node:path');
const multer = require('multer');
const fs = require('node:fs');

const { authenticate, optionalAuth } = require('./middleware/auth');
const authCtrl = require('./controllers/auth');
const spotsCtrl = require('./controllers/spots');
const catchesCtrl = require('./controllers/catches');
const weatherCtrl = require('./controllers/weather');
const statsCtrl = require('./controllers/stats');
const followsCtrl = require('./controllers/follows');
const notificationsCtrl = require('./controllers/notifications');
const searchCtrl = require('./controllers/search');
const reviewsCtrl = require('./controllers/reviews');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files for uploaded images
const uploadsDir = path.join(__dirname, '..', 'public', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Multer storage for image upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `fish_${Date.now()}_${Math.floor(Math.random() * 1000)}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp|gif/;
    const ext = path.extname(file.originalname).toLowerCase();
    const mime = file.mimetype.toLowerCase();
    if (allowedTypes.test(ext) && (mime.startsWith('image/') || mime === 'application/octet-stream')) {
      return cb(null, true);
    }
    cb(new Error('仅支持上传图片格式文件 (jpg, png, webp, gif)'));
  },
});

// Simple sliding-window rate limiter for sensitive endpoints
const rateLimitMap = new Map();
function rateLimiter(windowMs, maxRequests, message = '操作过于频繁，请稍后再试') {
  return (req, res, next) => {
    const ip = req.ip || req.socket.remoteAddress || '127.0.0.1';
    const key = `${req.path}_${ip}`;
    const now = Date.now();
    const timestamps = rateLimitMap.get(key) || [];
    const validTimestamps = timestamps.filter(t => now - t < windowMs);

    if (validTimestamps.length >= maxRequests) {
      return res.status(429).json({ code: 429, message });
    }

    validTimestamps.push(now);
    rateLimitMap.set(key, validTimestamps);
    next();
  };
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'FisherMan Backend API (钓鱼佬)',
    version: '1.1.0',
    timestamp: new Date().toISOString(),
  });
});

// Auth routes
app.post('/api/auth/register', rateLimiter(60000, 3, '注册过于频繁，请稍后再试'), authCtrl.register);
app.post('/api/auth/login', rateLimiter(60000, 5, '登录尝试过于频繁，请1分钟后再试'), authCtrl.login);
app.post('/api/auth/refresh', authCtrl.refreshToken);
app.get('/api/auth/me', authenticate, authCtrl.getMe);
app.put('/api/auth/profile', authenticate, authCtrl.updateProfile);
app.get('/api/users/:id', optionalAuth, authCtrl.getUserProfile);
app.post('/api/users/:id/follow', authenticate, followsCtrl.toggleFollow);
app.get('/api/users/:id/followers', optionalAuth, followsCtrl.getFollowers);
app.get('/api/users/:id/following', optionalAuth, followsCtrl.getFollowing);

// Notifications
app.get('/api/notifications', authenticate, notificationsCtrl.listNotifications);
app.get('/api/notifications/unread-count', authenticate, notificationsCtrl.getUnreadCount);
app.put('/api/notifications/read', authenticate, notificationsCtrl.markAllRead);
app.get('/api/search', searchCtrl.search);

// Spots routes
app.get('/api/spots', optionalAuth, spotsCtrl.listSpots);
app.get('/api/spots/:id', optionalAuth, spotsCtrl.getSpotDetail);
app.post('/api/spots', authenticate, spotsCtrl.createSpot);
app.get('/api/spots/:id/reviews', reviewsCtrl.listReviews);
app.post('/api/spots/:id/reviews', authenticate, reviewsCtrl.addReview);
app.put('/api/spots/:id', authenticate, spotsCtrl.updateSpot);
app.delete('/api/spots/:id', authenticate, spotsCtrl.deleteSpot);
app.post('/api/spots/:id/favorite', authenticate, spotsCtrl.toggleFavorite);
app.get('/api/my/favorites', authenticate, spotsCtrl.getMyFavorites);

// Catches routes
app.get('/api/catches', optionalAuth, catchesCtrl.listCatches);
app.get('/api/catches/:id', optionalAuth, catchesCtrl.getCatchDetail);
app.post('/api/catches', authenticate, rateLimiter(60000, 10, '发布战报过于频繁，请稍后再试'), catchesCtrl.createCatch);
app.put('/api/catches/:id', authenticate, catchesCtrl.updateCatch);
app.delete('/api/catches/:id', authenticate, catchesCtrl.deleteCatch);
app.post('/api/catches/:id/like', authenticate, catchesCtrl.toggleLike);
app.post('/api/catches/:id/comments', authenticate, rateLimiter(60000, 20, '评论过于频繁，请稍后再试'), catchesCtrl.addComment);
app.delete('/api/catches/:id/comments/:commentId', authenticate, catchesCtrl.deleteComment);

// Weather & Fishing Index
app.get('/api/weather', weatherCtrl.getFishingWeather);

// Platform Stats & Leaderboard
app.get('/api/stats', statsCtrl.getOverviewStats);
app.get('/api/stats/my', authenticate, statsCtrl.getMyStats);

// Upload endpoint
app.post('/api/upload', authenticate, upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ code: 400, message: '请选择要上传的图片' });
  }
  const fileUrl = `/uploads/${req.file.filename}`;
  res.json({
    code: 200,
    message: '上传成功',
    data: { url: fileUrl },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ code: 404, message: `接口不存在: ${req.method} ${req.url}` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('API Error:', err);
  res.status(500).json({
    code: 500,
    message: '服务器繁忙，请稍后再试',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

module.exports = app;
