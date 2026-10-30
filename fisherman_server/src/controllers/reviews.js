const db = require('../db');

exports.addReview = (req, res) => {
  const spotId = Number(req.params.id);
  const userId = req.user.id;
  const { rating, content } = req.body;

  const parsedRating = Number(rating);
  if (!Number.isInteger(parsedRating) || parsedRating < 1 || parsedRating > 5) {
    return res.status(400).json({ code: 400, message: '评分必须在1-5之间' });
  }

  const spot = db.prepare('SELECT id FROM spots WHERE id = ?').get(spotId);
  if (!spot) {
    return res.status(404).json({ code: 404, message: '钓点不存在' });
  }

  try {
    db.prepare(`
      INSERT INTO spot_reviews (spot_id, user_id, rating, content)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(spot_id, user_id) DO UPDATE SET rating=excluded.rating, content=excluded.content
    `).run(spotId, userId, parsedRating, content || '');

    // Update avg_rating on spots
    const avgResult = db.prepare('SELECT ROUND(AVG(rating), 1) as avg FROM spot_reviews WHERE spot_id = ?').get(spotId);
    db.prepare('UPDATE spots SET avg_rating = ? WHERE id = ?').run(avgResult.avg || 0, spotId);

    res.json({ code: 200, message: '评价提交成功' });
  } catch (e) {
    res.status(500).json({ code: 500, message: '提交失败' });
  }
};

exports.listReviews = (req, res) => {
  const spotId = Number(req.params.id);
  const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
  const offset = Math.max(Number(req.query.offset) || 0, 0);

  const spot = db.prepare('SELECT id FROM spots WHERE id = ?').get(spotId);
  if (!spot) {
    return res.status(404).json({ code: 404, message: '钓点不存在' });
  }

  const rows = db.prepare(`
    SELECT r.*, u.nickname as user_nickname, u.avatar as user_avatar
    FROM spot_reviews r
    JOIN users u ON r.user_id = u.id
    WHERE r.spot_id = ?
    ORDER BY r.created_at DESC
    LIMIT ? OFFSET ?
  `).all(spotId, limit, offset);

  const avgResult = db.prepare('SELECT ROUND(AVG(rating), 1) as avg, COUNT(*) as count FROM spot_reviews WHERE spot_id = ?').get(spotId);

  res.json({
    code: 200,
    data: {
      reviews: rows.map(r => ({
        id: r.id,
        userId: r.user_id,
        userNickname: r.user_nickname,
        userAvatar: r.user_avatar,
        rating: r.rating,
        content: r.content,
        createdAt: r.created_at,
      })),
      avgRating: avgResult.avg || 0,
      totalCount: avgResult.count,
    },
  });
};
