const db = require('../db');

function createNotification(userId, type, actorId, actorNickname, actorAvatar, targetType, targetId, content) {
  db.prepare(`
    INSERT INTO notifications (user_id, type, actor_id, actor_nickname, actor_avatar, target_type, target_id, content)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(userId, type, actorId, actorNickname, actorAvatar, targetType, targetId, content);
}

exports.createNotification = createNotification;

exports.listNotifications = (req, res) => {
  const userId = req.user.id;
  const limit = Math.min(Math.max(Number(req.query.limit) || 30, 1), 100);
  const offset = Math.max(Number(req.query.offset) || 0, 0);

  const rows = db.prepare(`
    SELECT * FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
  `).all(userId, Number(limit), Number(offset));

  const unreadCount = db.prepare(`
    SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0
  `).get(userId).count;

  res.json({
    code: 200,
    data: {
      notifications: rows.map(n => ({
        id: n.id,
        type: n.type,
        actorId: n.actor_id,
        actorNickname: n.actor_nickname,
        actorAvatar: n.actor_avatar,
        targetType: n.target_type,
        targetId: n.target_id,
        content: n.content,
        isRead: Boolean(n.is_read),
        createdAt: n.created_at,
      })),
      unreadCount,
    },
  });
};

exports.markAllRead = (req, res) => {
  const userId = req.user.id;
  db.prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?').run(userId);
  res.json({ code: 200, message: '已全部标为已读' });
};

exports.getUnreadCount = (req, res) => {
  const userId = req.user.id;
  const count = db.prepare('SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0').get(userId).count;
  res.json({ code: 200, data: { count } });
};
