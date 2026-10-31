# 🗄️ Database Schema & Data Dictionary

The FisherMan server utilizes native SQLite (`DatabaseSync` in Node 22+) in WAL mode with Foreign Key enforcement (`PRAGMA foreign_keys = ON`).

---

## 1. Table Definitions

### `users`
Stores registered angler credentials, personal profile, and fishing experience.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique user identifier |
| `username` | TEXT | UNIQUE, NOT NULL | Account login username |
| `password_hash`| TEXT | NOT NULL | Bcrypt hashed password |
| `nickname` | TEXT | NOT NULL | Angler display name |
| `avatar` | TEXT | DEFAULT '' | Avatar image URL |
| `bio` | TEXT | DEFAULT '永不空军，钓获放流！' | Bio description |
| `fishing_years`| INTEGER| DEFAULT 1 | Years of fishing experience |
| `target_fish` | TEXT | DEFAULT '鲫鱼、鲤鱼、鲈鱼' | Target fish species |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Registration timestamp |

---

### `spots`
Crowdsourced water bodies, reservoirs, streams, and pay lakes.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique spot ID |
| `name` | TEXT | NOT NULL | Spot title |
| `description` | TEXT | | Detailed environment & fish report |
| `lat` | REAL | NOT NULL | Latitude (-90 to 90) |
| `lng` | REAL | NOT NULL | Longitude (-180 to 180) |
| `water_type` | TEXT | DEFAULT '野钓' | Wild, Reservoir, Stream, Lake, BlackPit, Sea |
| `charge_type` | TEXT | DEFAULT '免费' | Free, By Day, By Weight |
| `fee_desc` | TEXT | DEFAULT '完全免费' | Charge description |
| `fish_types` | TEXT | DEFAULT '[]' | JSON array of present fish species |
| `depth_meters` | REAL | DEFAULT 2.0 | Average water depth in meters |
| `rules` | TEXT | | Environmental & safety rules |
| `address` | TEXT | | Locality name or landmark |
| `creator_id` | INTEGER| REFERENCES users(id) ON DELETE SET NULL | Spot author |
| `image_url` | TEXT | | Cover image URL |
| `likes_count` | INTEGER| DEFAULT 0 | Favorite/Like count |
| `avg_rating` | REAL | DEFAULT 0 | Cached average review rating (1.0-5.0) |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

---

### `catches`
Bragging catches submitted by anglers.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Catch record ID |
| `user_id` | INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Author angler ID |
| `spot_id` | INTEGER | REFERENCES spots(id) ON DELETE SET NULL | Checked-in spot ID |
| `spot_name` | TEXT | | Name of water location |
| `fish_type` | TEXT | NOT NULL | e.g., 翘嘴, 鲫鱼, 加州鲈 |
| `weight_kg` | REAL | NOT NULL | Catch weight in kilograms |
| `length_cm` | REAL | DEFAULT 0 | Catch length in centimeters |
| `fishing_method`| TEXT | DEFAULT '台钓' | Method (台钓, 路亚, 传统钓, 飞钓) |
| `depth_m` | REAL | DEFAULT 2.0 | Catch water depth |
| `bait` | TEXT | DEFAULT '蚯蚓/商品饵' | Bait / Lure used |
| `photo_url` | TEXT | | Real photo URL |
| `notes` | TEXT | | Field notes & angler experience |
| `likes_count` | INTEGER| DEFAULT 0 | Number of likes received |
| `comments_count`| INTEGER| DEFAULT 0 | Number of comments received |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Submission timestamp |

---

### `comments`
Comments and discussions on catches.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Comment ID |
| `catch_id` | INTEGER | NOT NULL, REFERENCES catches(id) ON DELETE CASCADE | Associated catch ID |
| `user_id` | INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Commenter ID |
| `parent_id` | INTEGER | DEFAULT NULL | Parent comment ID for nested replies |
| `content` | TEXT | NOT NULL | Comment text content |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

---

### `likes`
Like toggles for catches.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Primary key |
| `user_id` | INTEGER | NOT NULL | User who liked |
| `target_type` | TEXT | NOT NULL | Target entity type (`catch`) |
| `target_id` | INTEGER | NOT NULL | Target record ID |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

*Constraint*: `UNIQUE(user_id, target_type, target_id)`

---

### `favorites`
Favorite spots saved by anglers.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Primary key |
| `user_id` | INTEGER | NOT NULL | User saving the spot |
| `spot_id` | INTEGER | NOT NULL | Spot ID |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

*Constraint*: `UNIQUE(user_id, spot_id)`

---

### `follows`
Angler social graph.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Primary key |
| `follower_id` | INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Follower |
| `following_id`| INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Followed user |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

*Constraint*: `UNIQUE(follower_id, following_id)`

---

### `notifications`
In-app alert feed.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Primary key |
| `user_id` | INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Recipient user |
| `type` | TEXT | NOT NULL | `like`, `comment`, `follow`, `system` |
| `actor_id` | INTEGER | | Trigger user ID |
| `actor_nickname`| TEXT | | Trigger user nickname |
| `actor_avatar` | TEXT | | Trigger user avatar |
| `target_type` | TEXT | | `catch`, `spot`, `user` |
| `target_id` | INTEGER | | Target ID |
| `content` | TEXT | NOT NULL | Message text |
| `is_read` | INTEGER | DEFAULT 0 | 0 = unread, 1 = read |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

---

### `spot_reviews`
1-5 star ratings and reviews for spots.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Primary key |
| `spot_id` | INTEGER | NOT NULL, REFERENCES spots(id) ON DELETE CASCADE | Spot ID |
| `user_id` | INTEGER | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Reviewer ID |
| `rating` | INTEGER | NOT NULL CHECK(rating >= 1 AND rating <= 5) | Star rating |
| `content` | TEXT | | Review text |
| `created_at` | DATETIME| DEFAULT CURRENT_TIMESTAMP | Timestamp |

*Constraint*: `UNIQUE(spot_id, user_id)`
