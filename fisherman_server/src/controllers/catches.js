const db = require('../db');

exports.listCatches = (req, res) => {
  const { fishType, spotId, userId, limit = 50 } = req.query;
  const currentUserId = req.user?.id || 0;

  let query = `
    SELECT 
      c.*,
      u.nickname as user_nickname,
      u.avatar as user_avatar,
      u.fishing_years as user_fishing_years,
      s.address as spot_address,
      s.lat as spot_lat,
      s.lng as spot_lng,
      s.water_type as spot_water_type,
      s.charge_type as spot_charge_type,
      s.depth_meters as spot_depth_meters,
      EXISTS(SELECT 1 FROM likes l WHERE l.target_type = 'catch' AND l.target_id = c.id AND l.user_id = ?) as is_liked
    FROM catches c
    JOIN users u ON c.user_id = u.id
    LEFT JOIN spots s ON c.spot_id = s.id
    WHERE 1=1
  `;
  const params = [currentUserId];

  if (fishType && fishType !== '全部') {
    query += ` AND c.fish_type LIKE ?`;
    params.push(`%${fishType}%`);
  }

  if (spotId) {
    query += ` AND c.spot_id = ?`;
    params.push(Number(spotId));
  }

  if (userId) {
    query += ` AND c.user_id = ?`;
    params.push(Number(userId));
  }

  query += ` ORDER BY c.created_at DESC LIMIT ?`;
  params.push(Number(limit));

  const rows = db.prepare(query).all(...params);

  res.json({
    code: 200,
    data: rows.map(r => ({
      id: r.id,
      userId: r.user_id,
      userNickname: r.user_nickname,
      userAvatar: r.user_avatar,
      userFishingYears: r.user_fishing_years,
      spotId: r.spot_id,
      spotName: r.spot_name || '秘密水域',
      spotAddress: r.spot_address || `${r.spot_name || '优质自然水域'} • 户外垂钓点`,
      spotLat: r.spot_lat != null ? r.spot_lat : 30.244,
      spotLng: r.spot_lng != null ? r.spot_lng : 120.145,
      spotWaterType: r.spot_water_type || '野钓',
      spotChargeType: r.spot_charge_type || '免费',
      fishType: r.fish_type,
      weightKg: r.weight_kg,
      lengthCm: r.length_cm,
      fishingMethod: r.fishing_method,
      depthM: r.depth_m,
      bait: r.bait,
      photoUrl: r.photo_url,
      notes: r.notes,
      likesCount: r.likes_count,
      commentsCount: r.comments_count,
      isLiked: Boolean(r.is_liked),
      createdAt: r.created_at,
    })),
  });
};

exports.getCatchDetail = (req, res) => {
  const catchId = Number(req.params.id);
  const currentUserId = req.user?.id || 0;

  const r = db.prepare(`
    SELECT 
      c.*,
      u.nickname as user_nickname,
      u.avatar as user_avatar,
      u.fishing_years as user_fishing_years,
      s.address as spot_address,
      s.lat as spot_lat,
      s.lng as spot_lng,
      s.water_type as spot_water_type,
      s.charge_type as spot_charge_type,
      s.depth_meters as spot_depth_meters,
      EXISTS(SELECT 1 FROM likes l WHERE l.target_type = 'catch' AND l.target_id = c.id AND l.user_id = ?) as is_liked
    FROM catches c
    JOIN users u ON c.user_id = u.id
    LEFT JOIN spots s ON c.spot_id = s.id
    WHERE c.id = ?
  `).get(currentUserId, catchId);

  if (!r) {
    return res.status(404).json({ code: 404, message: '渔获记录不存在' });
  }

  const comments = db.prepare(`
    SELECT cm.*, u.nickname as user_nickname, u.avatar as user_avatar
    FROM comments cm
    JOIN users u ON cm.user_id = u.id
    WHERE cm.catch_id = ?
    ORDER BY cm.created_at ASC
  `).all(catchId);

  res.json({
    code: 200,
    data: {
      id: r.id,
      userId: r.user_id,
      userNickname: r.user_nickname,
      userAvatar: r.user_avatar,
      userFishingYears: r.user_fishing_years,
      spotId: r.spot_id,
      spotName: r.spot_name || '秘密水域',
      spotAddress: r.spot_address || `${r.spot_name || '优质自然水域'} • 户外垂钓点`,
      spotLat: r.spot_lat != null ? r.spot_lat : 30.244,
      spotLng: r.spot_lng != null ? r.spot_lng : 120.145,
      spotWaterType: r.spot_water_type || '野钓',
      spotChargeType: r.spot_charge_type || '免费',
      fishType: r.fish_type,
      weightKg: r.weight_kg,
      lengthCm: r.length_cm,
      fishingMethod: r.fishing_method,
      depthM: r.depth_m,
      bait: r.bait,
      photoUrl: r.photo_url,
      notes: r.notes,
      likesCount: r.likes_count,
      commentsCount: r.comments_count,
      isLiked: Boolean(r.is_liked),
      comments: comments.map(c => ({
        id: c.id,
        userId: c.user_id,
        userNickname: c.user_nickname,
        userAvatar: c.user_avatar,
        content: c.content,
        createdAt: c.created_at,
      })),
      createdAt: r.created_at,
    },
  });
};

exports.createCatch = (req, res) => {
  const {
    spotId,
    spotName,
    fishType,
    weightKg,
    lengthCm,
    fishingMethod,
    depthM,
    bait,
    photoUrl,
    notes,
  } = req.body;

  if (!fishType || weightKg === undefined) {
    return res.status(400).json({ code: 400, message: '鱼种与重量不能为空' });
  }

  // If spotId provided but no spotName, look it up
  let finalSpotName = spotName;
  if (spotId && !finalSpotName) {
    const s = db.prepare('SELECT name FROM spots WHERE id = ?').get(spotId);
    if (s) finalSpotName = s.name;
  }

  const result = db.prepare(`
    INSERT INTO catches (
      user_id, spot_id, spot_name, fish_type, weight_kg, length_cm,
      fishing_method, depth_m, bait, photo_url, notes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    req.user.id,
    spotId || null,
    finalSpotName || '自由水域',
    fishType,
    parseFloat(weightKg),
    parseFloat(lengthCm || 0),
    fishingMethod || '台钓',
    parseFloat(depthM || 2.0),
    bait || '商品饵/活饵',
    photoUrl || 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
    notes || '今日大捷，不虚此行！'
  );

  res.status(201).json({
    code: 200,
    message: '渔获战报发布成功！恭喜大师！',
    data: { id: result.lastInsertRowid },
  });
};

exports.toggleLike = (req, res) => {
  const catchId = Number(req.params.id);
  const userId = req.user.id;

  const existing = db.prepare(`
    SELECT id FROM likes WHERE user_id = ? AND target_type = 'catch' AND target_id = ?
  `).get(userId, catchId);

  if (existing) {
    db.prepare('DELETE FROM likes WHERE id = ?').run(existing.id);
    db.prepare('UPDATE catches SET likes_count = MAX(0, likes_count - 1) WHERE id = ?').run(catchId);
    const updated = db.prepare('SELECT likes_count FROM catches WHERE id = ?').get(catchId);
    return res.json({
      code: 200,
      message: '已取消点赞',
      data: { isLiked: false, likesCount: updated.likes_count },
    });
  } else {
    db.prepare(`INSERT INTO likes (user_id, target_type, target_id) VALUES (?, 'catch', ?)`).run(userId, catchId);
    db.prepare('UPDATE catches SET likes_count = likes_count + 1 WHERE id = ?').run(catchId);
    const updated = db.prepare('SELECT likes_count FROM catches WHERE id = ?').get(catchId);
    return res.json({
      code: 200,
      message: '点赞成功',
      data: { isLiked: true, likesCount: updated.likes_count },
    });
  }
};

exports.addComment = (req, res) => {
  const catchId = Number(req.params.id);
  const { content } = req.body;

  if (!content || !content.trim()) {
    return res.status(400).json({ code: 400, message: '评论内容不能为空' });
  }

  const result = db.prepare(`
    INSERT INTO comments (catch_id, user_id, content) VALUES (?, ?, ?)
  `).run(catchId, req.user.id, content.trim());

  db.prepare('UPDATE catches SET comments_count = comments_count + 1 WHERE id = ?').run(catchId);

  res.status(201).json({
    code: 200,
    message: '评论成功',
    data: {
      id: result.lastInsertRowid,
      content: content.trim(),
      userNickname: req.user.nickname,
      userAvatar: req.user.avatar,
      createdAt: new Date().toISOString(),
    },
  });
};
