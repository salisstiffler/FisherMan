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

  // Popular fish types from actual catch data
  const popularFishesRaw = db.prepare(`
    SELECT fish_type as name, COUNT(*) as count
    FROM catches
    GROUP BY fish_type
    ORDER BY count DESC
    LIMIT 6
  `).all();

  const fishIcons = { '翘嘴': '🐟', '鲫鱼': '🐡', '加州鲈': '🎣', '鳜鱼': '🐠', '草鱼': '🐟', '马口': '🐟', '鲤鱼': '🦋', '黑鱼': '🐠', '鳊鱼': '🐟' };
  const popularFishes = popularFishesRaw.map(f => ({
    name: f.name,
    icon: fishIcons[f.name] || '🎣',
    count: f.count,
  }));

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

exports.getMyStats = (req, res) => {
  const userId = req.user.id;

  // Monthly catch counts for last 6 months
  const monthly = db.prepare(`
    SELECT
      strftime('%Y-%m', created_at) as month,
      COUNT(*) as catch_count,
      ROUND(SUM(weight_kg), 1) as total_weight
    FROM catches
    WHERE user_id = ?
      AND created_at >= date('now', '-6 months')
    GROUP BY month
    ORDER BY month ASC
  `).all(userId);

  // Fish type distribution
  const fishDistribution = db.prepare(`
    SELECT fish_type as name, COUNT(*) as count
    FROM catches
    WHERE user_id = ?
    GROUP BY fish_type
    ORDER BY count DESC
    LIMIT 8
  `).all(userId);

  res.json({
    code: 200,
    data: { monthly, fishDistribution },
  });
};
