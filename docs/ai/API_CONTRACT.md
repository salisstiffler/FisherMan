# 📡 API Contract & Payload Reference

All backend responses conform to the standard FisherMan JSON envelope:

```json
{
  "code": 200,
  "message": "Success message",
  "data": { ... }
}
```

HTTP status codes map directly to the envelope `code` (200, 201, 400, 401, 403, 404, 500).

---

## 1. Authentication & Users

### `POST /api/auth/register`
- **Request**:
```json
{
  "username": "angler_bob",
  "password": "mypassword123",
  "nickname": "Bob the Caster"
}
```
- **Response `data`**:
```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "user": {
    "id": 5,
    "username": "angler_bob",
    "nickname": "Bob the Caster",
    "avatar": "https://...",
    "fishing_years": 1,
    "target_fish": "鲫鱼、白条",
    "stats": { ... }
  }
}
```

### `POST /api/auth/login`
- **Request**: `{ "username": "diaoyu1", "password": "password" }`
- **Response `data`**: Same as register response.

### `POST /api/auth/refresh`
- **Request**: `{ "refreshToken": "eyJhbGciOi..." }`
- **Response `data`**:
```json
{
  "token": "eyJhbGciOi...(new)",
  "refreshToken": "eyJhbGciOi...(new)"
}
```

### `GET /api/users/:id` (Optional Auth)
- Returns public angler profile, follow status (`isFollowing`), and stats with badge breakdown.

---

## 2. Spots & Reviews

### `GET /api/spots`
- **Query Params**:
  - `keyword`: text search
  - `water_type`: '野钓' | '水库' | '溪流' | '湖泊' | '黑坑' | '海钓'
  - `charge_type`: '免费' | '按天' | '按斤'
  - `creatorId`: integer
  - `lat`, `lng`: User coordinates for distance calculation (`distanceKm`)

### `POST /api/spots` (Auth required)
- **Request**:
```json
{
  "name": "千岛湖羡山半岛",
  "description": "铧尖水深4.5米，翘嘴聚集区",
  "lat": 29.5623,
  "lng": 119.0432,
  "waterType": "水库",
  "chargeType": "免费",
  "feeDesc": "完全免费",
  "fishTypes": ["翘嘴", "青鱼"],
  "depthMeters": 4.5,
  "rules": "穿戴救生衣，禁止带走垃圾",
  "address": "浙江省杭州市淳安县羡山半岛",
  "imageUrl": "https://..."
}
```

### `POST /api/spots/:id/reviews` (Auth required)
- **Request**: `{ "rating": 5, "content": "大鱼频现，老板热情！" }`

---

## 3. Catches & Community

### `GET /api/catches`
- **Query Params**:
  - `fishType`: species filter
  - `spotId`: check-in spot filter
  - `userId`: angler filter
  - `limit`: defaults to 50 (max 100)
  - `offset`: pagination offset (0, 50, 100...)

### `POST /api/catches` (Auth required)
- **Request**:
```json
{
  "spotId": 1,
  "spotName": "千岛湖羡山半岛",
  "fishType": "翘嘴",
  "weightKg": 7.8,
  "lengthCm": 86.5,
  "fishingMethod": "路亚",
  "depthM": 4.5,
  "bait": "14g 沉水米诺",
  "photoUrl": "https://...",
  "notes": "第一竿爆截，大鱼冲刺极具冲击力！"
}
```

### `POST /api/catches/:id/comments` (Auth required)
- **Request**: `{ "content": "请教大师使用的线组搭配？", "parentId": null }`

---

## 4. Weather & Barometric Index

### `GET /api/weather`
- **Query Params**: `lat`, `lng`
- **Response `data`**:
```json
{
  "location": { "lat": 30.274, "lng": 120.155 },
  "temperature": "22°C",
  "pressure": "1013.2 hPa",
  "humidity": "68%",
  "wind": "东南风 2-3级 微风",
  "fishingScore": 92,
  "fishingStatus": "爆护指数极高",
  "advice": "黄金气压区间！鱼类开口活跃，适宜出钓！",
  "hourlyForecast": [ ... ],
  "dailyForecast": [
    { "day": "今天", "tempRange": "16°C ~ 24°C", "pressureRange": "1011 ~ 1015 hPa", "fishingScore": 92, "status": "爆护指数极高" },
    { "day": "明天", "tempRange": "17°C ~ 25°C", "pressureRange": "1013 ~ 1016 hPa", "fishingScore": 94, "status": "大鱼频现" },
    { "day": "后天", "tempRange": "15°C ~ 22°C", "pressureRange": "1008 ~ 1012 hPa", "fishingScore": 78, "status": "平稳出钓" }
  ]
}
```
