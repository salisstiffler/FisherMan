const db = require('../db');

exports.search = (req, res) => {
  const query = String(req.query.q || '').trim();
  const type = String(req.query.type || 'all');
  if (!query) {
    return res.status(400).json({ code: 400, message: '请输入搜索内容' });
  }
  if (!['all', 'catches', 'spots', 'users'].includes(type)) {
    return res.status(400).json({ code: 400, message: '搜索类型无效' });
  }

  const keyword = `%${query}%`;
  const result = {};
  if (type === 'all' || type === 'catches') {
    result.catches = db.prepare(`
      SELECT c.id, c.user_id as userId, u.nickname as userNickname,
             u.avatar as userAvatar, c.fish_type as fishType,
             c.weight_kg as weightKg, c.photo_url as photoUrl,
             c.notes, c.created_at as createdAt
      FROM catches c
      JOIN users u ON u.id = c.user_id
      WHERE c.fish_type LIKE ? OR u.nickname LIKE ? OR c.notes LIKE ?
      ORDER BY c.created_at DESC
      LIMIT 30
    `).all(keyword, keyword, keyword);
  }
  if (type === 'all' || type === 'spots') {
    result.spots = db.prepare(`
      SELECT s.id, s.name, s.address, s.description, s.lat, s.lng,
             s.water_type as waterType, s.charge_type as chargeType,
             s.creator_id as creatorId, u.nickname as creatorNickname,
             u.avatar as creatorAvatar, s.image_url as imageUrl
      FROM spots s
      LEFT JOIN users u ON u.id = s.creator_id
      WHERE s.name LIKE ? OR s.address LIKE ? OR s.description LIKE ?
      ORDER BY s.id DESC
      LIMIT 30
    `).all(keyword, keyword, keyword);
  }
  if (type === 'all' || type === 'users') {
    result.users = db.prepare(`
      SELECT id, nickname, avatar, bio, fishing_years as fishingYears
      FROM users
      WHERE nickname LIKE ?
      ORDER BY nickname
      LIMIT 30
    `).all(keyword);
  }

  res.json({
    code: 200,
    data: type === 'all' ? result : result[type],
  });
};
