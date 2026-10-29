const db = require('../db');

exports.getOverviewStats = (req, res) => {
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
  const spotCount = db.prepare('SELECT COUNT(*) as count FROM spots').get().count;
  const catchCount = db.prepare('SELECT COUNT(*) as count FROM catches').get().count;
  const totalWeight = db.prepare('SELECT COALESCE(SUM(weight_kg), 0) as weight FROM catches').get().weight;

  // Leaderboard: top anglers by total catch weight
  const topAnglers = db.prepare(`
    SELECT 
      u.id, u.nickname, u.avatar, u.fishing_years,
      COUNT(c.id) as catch_count,
      ROUND(COALESCE(SUM(c.weight_kg), 0), 1) as total_weight_kg,
      ROUND(COALESCE(MAX(c.weight_kg), 0), 1) as max_weight_kg
    FROM users u
    JOIN catches c ON u.id = c.user_id
    GROUP BY u.id
    ORDER BY total_weight_kg DESC
    LIMIT 10
  `).all();

  // Popular fish types
  const popularFishes = [
    { name: '翘嘴', icon: '🐟', count: 128 },
    { name: '鲫鱼', icon: '🐡', count: 356 },
    { name: '加州鲈', icon: '🎣', count: 94 },
    { name: '鳜鱼', icon: '🐠', count: 62 },
    { name: '草鱼', icon: '🐟', count: 88 },
    { name: '马口', icon: '✨', count: 115 },
  ];

  res.json({
    code: 200,
    data: {
      totalAnglers: userCount,
      totalSpots: spotCount,
      totalCatches: catchCount,
      totalWeightKg: Math.round(totalWeight * 10) / 10,
      leaderboard: topAnglers,
      popularFishes,
    },
  });
};
