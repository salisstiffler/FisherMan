const db = require('../db');
const { createNotification } = require('./notifications');

exports.toggleFollow = (req, res) => {
  const followerId = req.user.id;
  const followingId = Number(req.params.id);

  if (followerId === followingId) {
    return res.status(400).json({ code: 400, message: '不能关注自己' });
  }

  const target = db.prepare('SELECT id, nickname, avatar FROM users WHERE id = ?').get(followingId);
  if (!target) {
    return res.status(404).json({ code: 404, message: '用户不存在' });
  }

  const existing = db.prepare('SELECT id FROM follows WHERE follower_id = ? AND following_id = ?').get(followerId, followingId);

  if (existing) {
    db.prepare('DELETE FROM follows WHERE id = ?').run(existing.id);
    return res.json({ code: 200, message: '已取消关注', data: { isFollowing: false } });
  } else {
    db.prepare('INSERT INTO follows (follower_id, following_id) VALUES (?, ?)').run(followerId, followingId);
    // Create notification for the followed user
    createNotification(
      followingId, 'follow', followerId,
      req.user.nickname, req.user.avatar,
      'user', followerId,
      `${req.user.nickname} 关注了你`
    );
    return res.json({ code: 200, message: '关注成功', data: { isFollowing: true } });
  }
};

exports.getFollowers = (req, res) => {
  const userId = Number(req.params.id);
  if (!Number.isInteger(userId) || userId < 1) {
    return res.status(400).json({ code: 400, message: '用户ID无效' });
  }
  const currentUserId = req.user?.id || 0;

  const rows = db.prepare(`
    SELECT u.id, u.nickname, u.avatar, u.bio, u.fishing_years,
           EXISTS(SELECT 1 FROM follows WHERE follower_id = ? AND following_id = u.id) as is_following
    FROM follows f
    JOIN users u ON f.follower_id = u.id
    WHERE f.following_id = ?
    ORDER BY f.created_at DESC
  `).all(currentUserId, userId);

  res.json({ code: 200, data: rows });
};

exports.getFollowing = (req, res) => {
  const userId = Number(req.params.id);
  if (!Number.isInteger(userId) || userId < 1) {
    return res.status(400).json({ code: 400, message: '用户ID无效' });
  }
  const currentUserId = req.user?.id || 0;

  const rows = db.prepare(`
    SELECT u.id, u.nickname, u.avatar, u.bio, u.fishing_years,
           EXISTS(SELECT 1 FROM follows WHERE follower_id = ? AND following_id = u.id) as is_following
    FROM follows f
    JOIN users u ON f.following_id = u.id
    WHERE f.follower_id = ?
    ORDER BY f.created_at DESC
  `).all(currentUserId, userId);

  res.json({ code: 200, data: rows });
};
