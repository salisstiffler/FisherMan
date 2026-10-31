const bcrypt = require('bcryptjs');
const db = require('../db');
const { generateToken, generateRefreshToken, verifyRefreshToken } = require('../middleware/auth');

function getUserStats(userId) {
  const spotCount = db.prepare('SELECT COUNT(*) as count FROM spots WHERE creator_id = ?').get(userId).count;
  const catchStats = db.prepare(`
    SELECT 
      COUNT(*) as count,
      COALESCE(SUM(weight_kg), 0) as total_weight,
      COALESCE(MAX(weight_kg), 0) as max_weight
    FROM catches WHERE user_id = ?
  `).get(userId);

  const favoriteCount = db.prepare('SELECT COUNT(*) as count FROM favorites WHERE user_id = ?').get(userId).count;

  const followersCount = db.prepare('SELECT COUNT(*) as count FROM follows WHERE following_id = ?').get(userId)?.count ?? 0;
  const followingCount = db.prepare('SELECT COUNT(*) as count FROM follows WHERE follower_id = ?').get(userId)?.count ?? 0;
  const speciesCount = db.prepare(
    'SELECT COUNT(DISTINCT fish_type) AS count FROM catches WHERE user_id = ?',
  ).get(userId).count;
  const catchDays = db.prepare(`
    SELECT DISTINCT date(created_at) AS catch_day
    FROM catches
    WHERE user_id = ? AND date(created_at) IS NOT NULL
    ORDER BY catch_day DESC
    LIMIT 365
  `).all(userId).map((row) => row.catch_day);
  let currentStreak = 0;
  let longestStreak = 0;
  let previousDay = null;
  for (const catchDay of catchDays) {
    const day = Date.parse(`${catchDay}T00:00:00Z`);
    const previous = previousDay == null
      ? null
      : Date.parse(`${previousDay}T00:00:00Z`);
    currentStreak = previous != null && previous - day === 86400000
      ? currentStreak + 1
      : 1;
    longestStreak = Math.max(longestStreak, currentStreak);
    previousDay = catchDay;
  }

  const badge = (id, name, icon, desc, target, current) => ({
    id,
    name,
    icon,
    desc,
    target,
    current: Math.round(current * 10) / 10,
    unlocked: current >= target,
  });
  const badges = [
    badge('first_blood', '破空先锋', '🎣', '首开纪录，成功发布第1尾战报', 1, catchStats.count),
    badge('veteran', '老钓骨', '🏆', '累计发布5次出钓战报', 5, catchStats.count),
    badge('monster_hunter', '巨物猎人', '🦈', '单尾渔获突破 5.0 kg', 5, catchStats.max_weight),
    badge('spot_explorer', '钓点拓荒者', '🗺️', '累计标记 2 个优质水域', 2, spotCount),
    badge('master_angler', '百斤大师', '👑', '累计渔获总重量达到 20 kg', 20, catchStats.total_weight),
    badge('famous_angler', '名扬钓界', '🌟', '拥有 3 位以上钓友粉丝', 3, followersCount),
    badge('species_collector', '鱼种收藏家', '🐠', '战报记录至少 5 种不同鱼类', 5, speciesCount),
    badge('streak_angler', '连竿达人', '🔥', '连续出钓记录达到 3 天', 3, longestStreak),
  ];

  return {
    spotsCreated: spotCount,
    catchesCount: catchStats.count,
    totalWeightKg: Math.round(catchStats.total_weight * 10) / 10,
    maxWeightKg: Math.round(catchStats.max_weight * 10) / 10,
    favoritesCount: favoriteCount,
    followersCount,
    followingCount,
    badges,
  };
}

exports.register = (req, res) => {
  const { username, password, nickname } = req.body;
  if (!username || !password || !nickname) {
    return res.status(400).json({ code: 400, message: '用户名、密码与昵称不能为空' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) {
    return res.status(400).json({ code: 400, message: '该用户名已被注册' });
  }

  const salt = bcrypt.genSaltSync(10);
  const passwordHash = bcrypt.hashSync(password, salt);

  const result = db.prepare(`
    INSERT INTO users (username, password_hash, nickname, avatar, bio, fishing_years, target_fish)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(
    username,
    passwordHash,
    nickname,
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    '新晋钓友，请多指教！',
    1,
    '鲫鱼、白条'
  );

  const user = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(result.lastInsertRowid);
  const token = generateToken(user);
  const refreshToken = generateRefreshToken(user);
  const stats = getUserStats(user.id);

  res.status(201).json({
    code: 200,
    message: '注册成功',
    data: {
      token,
      refreshToken,
      user: { ...user, stats },
    },
  });
};

exports.login = (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ code: 400, message: '请输入用户名和密码' });
  }

  const userWithPwd = db.prepare('SELECT * FROM users WHERE username = ?').get(username);
  if (!userWithPwd || !bcrypt.compareSync(password, userWithPwd.password_hash)) {
    return res.status(401).json({ code: 401, message: '用户名或密码错误' });
  }

  const { password_hash, ...user } = userWithPwd;
  const token = generateToken(user);
  const refreshToken = generateRefreshToken(user);
  const stats = getUserStats(user.id);

  res.json({
    code: 200,
    message: '登录成功',
    data: {
      token,
      refreshToken,
      user: { ...user, stats },
    },
  });
};

exports.getMe = (req, res) => {
  const user = req.user;
  const stats = getUserStats(user.id);
  res.json({
    code: 200,
    data: { ...user, stats },
  });
};

exports.updateProfile = (req, res) => {
  const userId = req.user.id;
  const { nickname, bio, fishing_years, target_fish, avatar } = req.body;

  db.prepare(`
    UPDATE users SET
      nickname = COALESCE(?, nickname),
      bio = COALESCE(?, bio),
      fishing_years = COALESCE(?, fishing_years),
      target_fish = COALESCE(?, target_fish),
      avatar = COALESCE(?, avatar)
    WHERE id = ?
  `).run(nickname, bio, fishing_years, target_fish, avatar, userId);

  const updatedUser = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(userId);
  const stats = getUserStats(userId);

  res.json({
    code: 200,
    message: '资料更新成功',
    data: { ...updatedUser, stats },
  });
};

exports.getUserProfile = (req, res) => {
  const targetId = Number(req.params.id);
  const user = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(targetId);
  if (!user) {
    return res.status(404).json({ code: 404, message: '用户不存在' });
  }
  const stats = getUserStats(targetId);
  const viewerId = req.user?.id || 0;
  const isFollowing = viewerId ? Boolean(db.prepare('SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ?').get(viewerId, targetId)) : false;
  res.json({
    code: 200,
    data: { ...user, stats, isFollowing },
  });
};

exports.refreshToken = (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ code: 400, message: '请提供 refreshToken' });
  }

  const decoded = verifyRefreshToken(refreshToken);
  if (!decoded) {
    return res.status(401).json({ code: 401, message: 'refreshToken 无效或已过期，请重新登录' });
  }

  const user = db.prepare('SELECT id, username, nickname, avatar, bio, fishing_years, target_fish, created_at FROM users WHERE id = ?').get(decoded.id);
  if (!user) {
    return res.status(401).json({ code: 401, message: '用户不存在' });
  }

  const newToken = generateToken(user);
  const newRefreshToken = generateRefreshToken(user);

  res.json({
    code: 200,
    message: 'Token 刷新成功',
    data: {
      token: newToken,
      refreshToken: newRefreshToken,
    },
  });
};
