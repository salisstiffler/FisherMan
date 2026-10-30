const db = require('../db');

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

exports.listSpots = (req, res) => {
  const { keyword, water_type, charge_type, creatorId, lat, lng } = req.query;
  const currentUserId = req.user?.id || 0;

  let query = `
    SELECT 
      s.*,
      u.nickname as creator_nickname,
      u.avatar as creator_avatar,
      EXISTS(SELECT 1 FROM favorites f WHERE f.spot_id = s.id AND f.user_id = ?) as is_favorited,
      (SELECT COUNT(*) FROM catches c WHERE c.spot_id = s.id) as catch_count
    FROM spots s
    LEFT JOIN users u ON s.creator_id = u.id
    WHERE 1=1
  `;
  const params = [currentUserId];

  if (keyword) {
    query += ` AND (s.name LIKE ? OR s.description LIKE ? OR s.address LIKE ? OR s.fish_types LIKE ?)`;
    const kw = `%${keyword}%`;
    params.push(kw, kw, kw, kw);
  }

  if (water_type && water_type !== '全部') {
    query += ` AND s.water_type = ?`;
    params.push(water_type);
  }

  if (charge_type && charge_type !== '全部') {
    query += ` AND s.charge_type = ?`;
    params.push(charge_type);
  }

  if (creatorId) {
    query += ` AND s.creator_id = ?`;
    params.push(Number(creatorId));
  }

  query += ` ORDER BY s.id DESC`;

  const rows = db.prepare(query).all(...params);

  const userLat = lat ? parseFloat(lat) : null;
  const userLng = lng ? parseFloat(lng) : null;

  const result = rows.map(row => {
    let fishTypes = [];
    try {
      fishTypes = JSON.parse(row.fish_types || '[]');
    } catch {
      fishTypes = [];
    }

    let distanceKm = null;
    if (userLat !== null && userLng !== null) {
      distanceKm = calculateDistance(userLat, userLng, row.lat, row.lng);
    }

    return {
      id: row.id,
      name: row.name,
      description: row.description,
      lat: row.lat,
      lng: row.lng,
      waterType: row.water_type,
      chargeType: row.charge_type,
      feeDesc: row.fee_desc,
      fishTypes,
      depthMeters: row.depth_meters,
      rules: row.rules,
      address: row.address,
      creatorId: row.creator_id,
      creatorNickname: row.creator_nickname || '钓点发现者',
      creatorAvatar: row.creator_avatar || '',
      imageUrl: row.image_url,
      likesCount: row.likes_count,
      catchCount: row.catch_count,
      avgRating: row.avg_rating || 0,
      isFavorited: Boolean(row.is_favorited),
      distanceKm,
      createdAt: row.created_at,
    };
  });

  // Sort by distance if user coords provided
  if (userLat !== null && userLng !== null) {
    result.sort((a, b) => (a.distanceKm ?? 99999) - (b.distanceKm ?? 99999));
  }

  res.json({
    code: 200,
    data: result,
  });
};

exports.getSpotDetail = (req, res) => {
  const spotId = Number(req.params.id);
  const currentUserId = req.user?.id || 0;

  const row = db.prepare(`
    SELECT 
      s.*,
      u.nickname as creator_nickname,
      u.avatar as creator_avatar,
      EXISTS(SELECT 1 FROM favorites f WHERE f.spot_id = s.id AND f.user_id = ?) as is_favorited,
      (SELECT COUNT(*) FROM catches c WHERE c.spot_id = s.id) as catch_count
    FROM spots s
    LEFT JOIN users u ON s.creator_id = u.id
    WHERE s.id = ?
  `).get(currentUserId, spotId);

  if (!row) {
    return res.status(404).json({ code: 404, message: '钓点不存在' });
  }

  let fishTypes = [];
  try {
    fishTypes = JSON.parse(row.fish_types || '[]');
  } catch {
    fishTypes = [];
  }

  // Get recent catches at this spot
  const recentCatches = db.prepare(`
    SELECT c.*, u.nickname as user_nickname, u.avatar as user_avatar
    FROM catches c
    JOIN users u ON c.user_id = u.id
    WHERE c.spot_id = ?
    ORDER BY c.created_at DESC
    LIMIT 6
  `).all(spotId);

  res.json({
    code: 200,
    data: {
      id: row.id,
      name: row.name,
      description: row.description,
      lat: row.lat,
      lng: row.lng,
      waterType: row.water_type,
      chargeType: row.charge_type,
      feeDesc: row.fee_desc,
      fishTypes,
      depthMeters: row.depth_meters,
      rules: row.rules,
      address: row.address,
      creatorId: row.creator_id,
      creatorNickname: row.creator_nickname || '钓点发现者',
      creatorAvatar: row.creator_avatar || '',
      imageUrl: row.image_url,
      likesCount: row.likes_count,
      catchCount: row.catch_count,
      avgRating: row.avg_rating || 0,
      isFavorited: Boolean(row.is_favorited),
      recentCatches: recentCatches.map(c => ({
        id: c.id,
        fishType: c.fish_type,
        weightKg: c.weight_kg,
        lengthCm: c.length_cm,
        fishingMethod: c.fishing_method,
        photoUrl: c.photo_url,
        notes: c.notes,
        userNickname: c.user_nickname,
        userAvatar: c.user_avatar,
        createdAt: c.created_at,
      })),
      createdAt: row.created_at,
    },
  });
};

exports.createSpot = (req, res) => {
  const {
    name,
    description,
    lat,
    lng,
    waterType,
    chargeType,
    feeDesc,
    fishTypes,
    depthMeters,
    rules,
    address,
    imageUrl,
  } = req.body;

  if (!name || lat === undefined || lng === undefined) {
    return res.status(400).json({ code: 400, message: '钓点名称和经纬度坐标不能为空' });
  }

  const result = db.prepare(`
    INSERT INTO spots (
      name, description, lat, lng, water_type, charge_type, fee_desc,
      fish_types, depth_meters, rules, address, creator_id, image_url
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    name,
    description || '钓友新标记的优质钓点',
    lat,
    lng,
    waterType || '野钓',
    chargeType || '免费',
    feeDesc || '免费开放',
    JSON.stringify(Array.isArray(fishTypes) ? fishTypes : ['鲫鱼', '鲤鱼']),
    depthMeters || 2.5,
    rules || '请文明垂钓，保护水资源环境',
    address || '自然水域',
    req.user.id,
    imageUrl || 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600'
  );

  res.status(201).json({
    code: 200,
    message: '钓点标记成功！感谢您的分享！',
    data: { id: result.lastInsertRowid },
  });
};

exports.toggleFavorite = (req, res) => {
  const spotId = Number(req.params.id);
  const userId = req.user.id;

  const existing = db.prepare('SELECT id FROM favorites WHERE user_id = ? AND spot_id = ?').get(userId, spotId);
  if (existing) {
    db.prepare('DELETE FROM favorites WHERE id = ?').run(existing.id);
    res.json({ code: 200, message: '已取消收藏', data: { isFavorited: false } });
  } else {
    db.prepare('INSERT INTO favorites (user_id, spot_id) VALUES (?, ?)').run(userId, spotId);
    res.json({ code: 200, message: '收藏成功', data: { isFavorited: true } });
  }
};

exports.getMyFavorites = (req, res) => {
  const userId = req.user.id;
  const rows = db.prepare(`
    SELECT s.*, 1 as is_favorited
    FROM favorites f
    JOIN spots s ON f.spot_id = s.id
    WHERE f.user_id = ?
    ORDER BY f.created_at DESC
  `).all(userId);

  const result = rows.map(row => {
    let fishTypes = [];
    try {
      fishTypes = JSON.parse(row.fish_types || '[]');
    } catch {
      fishTypes = [];
    }
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      lat: row.lat,
      lng: row.lng,
      waterType: row.water_type,
      chargeType: row.charge_type,
      feeDesc: row.fee_desc,
      fishTypes,
      depthMeters: row.depth_meters,
      address: row.address,
      imageUrl: row.image_url,
      isFavorited: true,
      createdAt: row.created_at,
    };
  });

  res.json({ code: 200, data: result });
};

exports.deleteSpot = (req, res) => {
  const spotId = Number(req.params.id);
  const userId = req.user.id;

  const spot = db.prepare('SELECT creator_id FROM spots WHERE id = ?').get(spotId);
  if (!spot) {
    return res.status(404).json({ code: 404, message: '钓点不存在' });
  }
  if (spot.creator_id !== userId) {
    return res.status(403).json({ code: 403, message: '无权删除他人创建的钓点' });
  }

  db.prepare('DELETE FROM favorites WHERE spot_id = ?').run(spotId);
  db.prepare('DELETE FROM spots WHERE id = ?').run(spotId);
  res.json({ code: 200, message: '钓点已删除' });
};

exports.updateSpot = (req, res) => {
  const spotId = Number(req.params.id);
  const userId = req.user.id;
  const { name, description, waterType, chargeType, feeDesc, depthMeters, rules, imageUrl } = req.body;

  const spot = db.prepare('SELECT creator_id FROM spots WHERE id = ?').get(spotId);
  if (!spot) {
    return res.status(404).json({ code: 404, message: '钓点不存在' });
  }
  if (spot.creator_id !== userId) {
    return res.status(403).json({ code: 403, message: '无权修改他人创建的钓点' });
  }

  const fields = [name, description, waterType, chargeType, feeDesc, depthMeters, rules, imageUrl];
  if (fields.every((value) => value === undefined)) {
    return res.status(400).json({ code: 400, message: '请提供要更新的钓点内容' });
  }
  const parsedDepth = depthMeters === undefined ? null : Number(depthMeters);
  if (depthMeters !== undefined && (!Number.isFinite(parsedDepth) || parsedDepth < 0)) {
    return res.status(400).json({ code: 400, message: '水深必须为非负数' });
  }

  db.prepare(`
    UPDATE spots SET
      name = COALESCE(?, name),
      description = COALESCE(?, description),
      water_type = COALESCE(?, water_type),
      charge_type = COALESCE(?, charge_type),
      fee_desc = COALESCE(?, fee_desc),
      depth_meters = COALESCE(?, depth_meters),
      rules = COALESCE(?, rules),
      image_url = COALESCE(?, image_url)
    WHERE id = ?
  `).run(name, description, waterType, chargeType, feeDesc, parsedDepth, rules, imageUrl, spotId);

  res.json({ code: 200, message: '钓点信息更新成功' });
};
