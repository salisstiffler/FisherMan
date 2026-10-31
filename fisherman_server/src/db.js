const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');
const fs = require('node:fs');
const bcrypt = require('bcryptjs');

const dbFile = process.env.DB_PATH || path.join(__dirname, '..', 'fisherman.db');
const dbDir = path.dirname(dbFile);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

const db = new DatabaseSync(dbFile);

// Enable WAL mode & foreign keys
db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA foreign_keys = ON;
`);

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      nickname TEXT NOT NULL,
      avatar TEXT DEFAULT '',
      bio TEXT DEFAULT '永不空军，钓获放流！',
      fishing_years INTEGER DEFAULT 1,
      target_fish TEXT DEFAULT '鲫鱼、鲤鱼、鲈鱼',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS spots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      water_type TEXT DEFAULT '野钓',
      charge_type TEXT DEFAULT '免费',
      fee_desc TEXT DEFAULT '完全免费',
      fish_types TEXT DEFAULT '[]',
      depth_meters REAL DEFAULT 2.0,
      rules TEXT DEFAULT '注意防滑，垃圾随手带走',
      address TEXT,
      creator_id INTEGER,
      image_url TEXT,
      likes_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS catches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      spot_id INTEGER,
      spot_name TEXT,
      fish_type TEXT NOT NULL,
      weight_kg REAL NOT NULL,
      length_cm REAL DEFAULT 0,
      fishing_method TEXT DEFAULT '台钓',
      depth_m REAL DEFAULT 2.0,
      bait TEXT DEFAULT '蚯蚓/商品饵',
      photo_url TEXT,
      notes TEXT,
      likes_count INTEGER DEFAULT 0,
      comments_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (spot_id) REFERENCES spots(id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      catch_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (catch_id) REFERENCES catches(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS likes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      target_type TEXT NOT NULL,
      target_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, target_type, target_id)
    );

    CREATE TABLE IF NOT EXISTS favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      spot_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, spot_id)
    );

    CREATE TABLE IF NOT EXISTS follows (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      follower_id INTEGER NOT NULL,
      following_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(follower_id, following_id),
      FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      actor_id INTEGER,
      actor_nickname TEXT,
      actor_avatar TEXT,
      target_type TEXT,
      target_id INTEGER,
      content TEXT NOT NULL,
      is_read INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS spot_reviews (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      spot_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
      content TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(spot_id, user_id),
      FOREIGN KEY (spot_id) REFERENCES spots(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Performance Indexes for 1.1 release
    CREATE INDEX IF NOT EXISTS idx_catches_user_created ON catches(user_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_catches_spot_created ON catches(spot_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_spots_coords ON spots(lat, lng);
    CREATE INDEX IF NOT EXISTS idx_spots_types ON spots(water_type, charge_type);
    CREATE INDEX IF NOT EXISTS idx_comments_catch ON comments(catch_id, created_at ASC);
    CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_follows_pair ON follows(follower_id, following_id);
    CREATE INDEX IF NOT EXISTS idx_spot_reviews_spot ON spot_reviews(spot_id, created_at DESC);
  `);

  // Add parent_id to comments if not exists
  try {
    db.exec(`ALTER TABLE comments ADD COLUMN parent_id INTEGER DEFAULT NULL`);
  } catch (e) {
    // Column already exists
  }
  // Add avg_rating to spots if not exists
  try {
    db.exec(`ALTER TABLE spots ADD COLUMN avg_rating REAL DEFAULT 0`);
  } catch (e) {
    // Column already exists
  }

  // Seed default data if users table is empty
  const countRow = db.prepare('SELECT COUNT(*) as cnt FROM users').get();
  if (countRow.cnt === 0) {
    seedData();
  }
}

function seedData() {
  console.log('🌱 Seeding initial fisherman data...');
  const salt = bcrypt.genSaltSync(10);
  const defaultPwdHash = bcrypt.hashSync('123456', salt);

  const insertUser = db.prepare(`
    INSERT INTO users (username, password_hash, nickname, avatar, bio, fishing_years, target_fish)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);

  insertUser.run('diaoyu1', defaultPwdHash, '空军总司令', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', '野钓三十载，依然热爱每一次扬竿！', 15, '大板鲫、青鱼、鲤鱼');
  insertUser.run('lure_pro', defaultPwdHash, '路亚狂徒小林', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', '搜寻水下每一个暴躁的咬口！', 6, '翘嘴、鲈鱼、鳜鱼');
  insertUser.run('old_carp', defaultPwdHash, '千岛湖老钓客', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', '心静自然鱼聚，钓获皆放生。', 20, '巨青、草鱼、鳙鱼');
  insertUser.run('stream_girl', defaultPwdHash, '溪流微物小圆', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', '山野清流间，追寻五彩马口与斑斓溪哥。', 3, '马口、溪哥、光唇鱼');

  const insertSpot = db.prepare(`
    INSERT INTO spots (name, description, lat, lng, water_type, charge_type, fee_desc, fish_types, depth_meters, rules, address, creator_id, image_url, likes_count)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertSpot.run(
    '千岛湖羡山半岛野钓点',
    '水质清澈见底达一类标准，缓坡铧尖位出鱼极好。清晨与傍晚翘嘴频繁炸水，底层常有大草鱼与青鱼巡游。',
    29.5623, 119.0432,
    '野钓', '免费', '免费开放水域',
    JSON.stringify(['翘嘴', '鳙鱼', '草鱼', '青鱼', '鳜鱼']),
    5.5,
    '请带走塑料袋饵料袋，严禁使用活体泥鳅打窝',
    '浙江省杭州市淳安县千岛湖羡山半岛环湖步道',
    1,
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
    42
  );

  insertSpot.run(
    '富春江芦茨湾溪流慢步道',
    '水质甘甜，风景如画的慢生活休闲体验区。水流平缓与乱石交错处是马口与光唇鱼绝佳标点，微物路亚或毛钩飞钓胜地。',
    29.7421, 119.6845,
    '溪流', '免费', '完全免费',
    JSON.stringify(['马口', '溪哥', '光唇鱼', '红尾']),
    2.2,
    '卵石湿滑请穿防滑涉水鞋，雷雨天切勿近水',
    '浙江省桐庐县富春江镇芦茨村溪畔',
    4,
    'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=600',
    28
  );

  insertSpot.run(
    '湘湖三期野钓长廊',
    '水域宽阔，水草丰美。两岸有栈道和防晒垂钓台，适合 3.6m~4.5m 传统钓与台钓，大板鲫和昂刺鱼密集。',
    30.1342, 120.2115,
    '野钓', '免费', '免费开放',
    JSON.stringify(['鲫鱼', '鲤鱼', '黄颡鱼', '黑鱼']),
    2.8,
    '一人限双竿，文明垂钓，不可使用倒刺三本钩',
    '浙江省杭州市萧山区湘湖路越王城下',
    1,
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600',
    35
  );

  insertSpot.run(
    '青山湖水上森林路亚基地',
    '国内知名路亚胜地，拥有独特的水上杉树林湿地。水草区与枯树桩周围潜伏大量加州鲈、凶猛黑鱼和大型鳜鱼。',
    30.2458, 119.7824,
    '水库', '按天', '100元/天 (含路亚艇租借优惠)',
    JSON.stringify(['加州鲈', '鳜鱼', '黑鱼', '翘嘴']),
    4.0,
    '倡导路亚 C&R (钓获放流)，不得私藏超标幼鱼',
    '浙江省杭州市临安区青山湖国家森林公园',
    2,
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600',
    56
  );

  insertSpot.run(
    '太湖东山野钓老码头',
    '湖风宜人，老码头水泥桩基下藏有成群的大鳊鱼与板鲫。秋风起时大青虾与红虫作饵，连竿不断。',
    31.0821, 120.4124,
    '野钓', '免费', '全天候免费',
    JSON.stringify(['大板鲫', '鳊鱼', '昂刺鱼', '草鱼']),
    3.2,
    '风浪大时请远离湿滑阶梯，夜钓务必佩戴救生衣',
    '江苏省苏州市吴中区东山镇太湖环岛大道',
    3,
    'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=600',
    19
  );

  const insertCatch = db.prepare(`
    INSERT INTO catches (user_id, spot_id, spot_name, fish_type, weight_kg, length_cm, fishing_method, depth_m, bait, photo_url, notes, likes_count, comments_count)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertCatch.run(
    2, 1, '千岛湖羡山半岛野钓点',
    '翘嘴', 7.8, 86.5,
    '路亚', 4.5, '14g 沉水米诺 (银背雷射)',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
    '清晨5点40分第一竿！在铧尖外侧水流交汇处一口爆截，线杯出线如同尖叫！溜了足足八分钟才入抄网，太爽了！',
    89, 12
  );

  insertCatch.run(
    1, 3, '湘湖三期野钓长廊',
    '鲫鱼', 1.35, 33.0,
    '台钓', 2.5, '自制酒米打窝 + 蓝鲫单开',
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600',
    '入秋后的黄金大板鲫，手感沉稳压手！漂相先轻轻上浮两目，然后稳稳下顿，提竿中鱼，手感极为美妙！',
    46, 6
  );

  insertCatch.run(
    2, 4, '青山湖水上森林路亚基地',
    '加州鲈', 2.4, 48.0,
    '路亚', 3.0, '3.5寸 T尾软虫 + 德州钓组',
    'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=600',
    '水杉根部标点精细作钓。轻跳两下后顿感一重，扬竿瞬间水花四溅洗鳃！拍照后已经安全放流！',
    63, 8
  );

  insertCatch.run(
    4, 2, '富春江芦茨湾溪流慢步道',
    '马口', 0.28, 22.0,
    '飞钓', 1.2, '#16号鹿毛干蝇',
    'https://images.unsplash.com/photo-1508873696983-2df5293cb325?w=600',
    '婚姻色极度绚烂的雄性大公马口！落蝇入水瞬间从卵石底冲上来抢食，溪流水质清澈，视觉冲击力拉满！',
    77, 15
  );

  // Insert seed comments
  const insertComment = db.prepare(`
    INSERT INTO comments (catch_id, user_id, content) VALUES (?, ?, ?)
  `);
  insertComment.run(1, 1, '太强了林大师！这个米诺什么克数？下次一起冲千岛湖！');
  insertComment.run(1, 3, '大翘嘴水上洗鳃那一下最刺激，恭喜破个人记录！');
  insertComment.run(1, 4, '这身段太修长健美了，真正的水下猎手！');
  insertComment.run(2, 2, '好正的黄金板鲫，鳞片金光闪闪，煲汤极鲜！');
  insertComment.run(3, 1, '钓获放流好样的！保护生态人人有责！');

  console.log('✅ Initial fisherman data seeded successfully.');
}

initSchema();

module.exports = db;
