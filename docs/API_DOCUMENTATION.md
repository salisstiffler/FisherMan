# 🎣「钓鱼佬」后端服务 API 接口规范与部署运维指南

本文档提供「钓鱼佬」后端 API 服务的完整接口规范、数据结构、本地快速调试指令及 Docker / 云原生部署方案。

---

## 一、服务架构概览

- **技术栈**：Node.js 22+ / Express 4.x / SQLite3 (利用 Node 22 原生 DatabaseSync 引擎，轻量、单文件、免 C++ 编译)
- **认证机制**：JWT (JSON Web Token)，Bearer 模式，有效期 30 天
- **默认监听端口**：`8080`
- **默认健康检查端点**：`GET /health`

---

## 二、核心 API 接口列表

### 1. 系统与健康检查
- `GET /health`
  - 返回服务运行状态、系统版本和当前服务器时间戳。

---

### 2. 用户与认证模块 (`/api/auth`)

#### 注册账号
- **URL**: `POST /api/auth/register`
- **Request Body**:
```json
{
  "username": "diaoyu_master",
  "password": "password123",
  "nickname": "千岛湖老钓客"
}
```
- **Response** (201 Created):
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "token": "eyJhbGciOi...",
    "user": {
      "id": 5,
      "username": "diaoyu_master",
      "nickname": "千岛湖老钓客",
      "avatar": "...",
      "fishing_years": 1,
      "target_fish": "鲫鱼、白条",
      "stats": {
        "spotsCreated": 0,
        "catchesCount": 0,
        "totalWeightKg": 0,
        "maxWeightKg": 0,
        "badges": []
      }
    }
  }
}
```

#### 用户登录
- **URL**: `POST /api/auth/login`
- **Request Body**:
```json
{
  "username": "diaoyu1",
  "password": "123456"
}
```

#### 获取当前用户资料与钓鱼勋章
- **URL**: `GET /api/auth/me`
- **Headers**: `Authorization: Bearer <token>`

#### 更新个人钓鱼档案
- **URL**: `PUT /api/auth/profile`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "nickname": "空军总司令",
  "bio": "心静自然凉，百竿皆不空！",
  "fishing_years": 16,
  "target_fish": "翘嘴、鳜鱼、大板鲫"
}
```

#### 获取指定钓友公开资料
- **URL**: `GET /api/users/:id`
- **Headers**: `Authorization: Bearer <token>` (可选)
- **Response**: 返回目标钓友公开个人信息、钓龄、目标鱼、勋章列表、统计信息（获赞、战报数、创建钓点数、粉丝数、关注数）以及当前访问者与该钓友的关注关系 (`isFollowing`)。

---

### 3. 钓点模块 (`/api/spots`)

#### 钓点列表检索 (支持地图范围、水系及收费方式筛选)
- **URL**: `GET /api/spots`
- **Query Parameters**:
  - `keyword`: 关键字搜索（钓点名称、地址、鱼种）
  - `water_type`: 水域类型（`野钓`、`水库`、`溪流`、`湖泊`、`黑坑`等）
  - `charge_type`: 收费形式（`免费`、`按天`、`按斤`等）
  - `lat`, `lng`: 当前用户经纬度（传入后将自动计算距离并按由近及远排序）

#### 钓点详情
- **URL**: `GET /api/spots/:id`
- **Response**: 返回钓点详细水深、环境规则、收费描述、出鱼鱼种及近期在此打卡的渔获记录。

#### 标记新增钓点
- **URL**: `POST /api/spots`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "name": "富春江芦茨湾慢步道钓点",
  "description": "卵石滩与缓流交界，微物路亚与马口绝佳标点",
  "lat": 29.7421,
  "lng": 119.6845,
  "waterType": "溪流",
  "chargeType": "免费",
  "feeDesc": "完全免费",
  "fishTypes": ["马口", "溪哥", "光唇鱼", "红尾"],
  "depthMeters": 2.2,
  "rules": "卵石湿滑请穿防滑鞋，带走生活垃圾",
  "address": "浙江省桐庐县富春江镇芦茨村",
  "imageUrl": "https://..."
}
```

#### 收藏/取消收藏钓点
- **URL**: `POST /api/spots/:id/favorite`
- **Headers**: `Authorization: Bearer <token>`

#### 钓点评分与评价 (1~5 星)
- **URL**: `POST /api/spots/:id/reviews`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "rating": 5,
  "content": "水质极佳，水草区多大板鲫，老板人实在，推荐来试！"
}
```

#### 获取钓点评价列表
- **URL**: `GET /api/spots/:id/reviews?limit=20&offset=0`
- **Response**: 返回评价列表、用户头像昵称、评分及钓点平均得分 (`avgRating`)。

#### 删除本人创建的钓点
- **URL**: `DELETE /api/spots/:id`
- **Headers**: `Authorization: Bearer <token>`

#### 修改本人创建的钓点信息
- **URL**: `PUT /api/spots/:id`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**: 支持更新钓点名称、描述、水域类型、收费描述、水深、规则及封面图。

---

### 4. 渔获与战报社区模块 (`/api/catches`)

#### 动态流获取
- **URL**: `GET /api/catches`
- **Query Parameters**:
  - `fishType`: 鱼种过滤（如 `翘嘴`、`加州鲈`、`鲫鱼`）
  - `spotId`: 指定钓点打卡流
  - `userId`: 指定钓友个人战报流

#### 发布新渔获战报
- **URL**: `POST /api/catches`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "spotId": 1,
  "spotName": "千岛湖羡山半岛野钓点",
  "fishType": "翘嘴",
  "weightKg": 7.8,
  "lengthCm": 86.5,
  "fishingMethod": "路亚",
  "depthM": 4.5,
  "bait": "14g 沉水米诺 (银背雷射)",
  "photoUrl": "https://...",
  "notes": "早晨第一竿在铧尖外侧水流交汇处爆截！手感极度炸裂！"
}
```

#### 渔获战报点赞 (支持切换)
- **URL**: `POST /api/catches/:id/like`
- **Headers**: `Authorization: Bearer <token>`

#### 战报评论与请教
- **URL**: `POST /api/catches/:id/comments`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "content": "大师牛逼！请教下子线搭配的是几号？",
  "parentId": null
}
```

#### 删除评论 (战报作者或评论本人)
- **URL**: `DELETE /api/catches/:catchId/comments/:commentId`
- **Headers**: `Authorization: Bearer <token>`

#### 删除本人发布的战报
- **URL**: `DELETE /api/catches/:id`
- **Headers**: `Authorization: Bearer <token>`

#### 编辑更新本人战报
- **URL**: `PUT /api/catches/:id`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "notes": "修改了用饵心得：下午换成红色软饵后连中3尾！",
  "fishingMethod": "精细路亚"
}
```

---

### 5. 社交互动与关注网络 (`/api/users`)

#### 关注/取消关注用户
- **URL**: `POST /api/users/:id/follow`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: 返回 `{ "isFollowing": true/false }`，并自动触发系统通知。

#### 获取粉丝列表
- **URL**: `GET /api/users/:id/followers`
- **Headers**: `Authorization: Bearer <token>` (可选)

#### 获取关注列表
- **URL**: `GET /api/users/:id/following`
- **Headers**: `Authorization: Bearer <token>` (可选)

---

### 6. 消息通知中心 (`/api/notifications`)

#### 获取通知列表与未读数
- **URL**: `GET /api/notifications?limit=30&offset=0`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: 包含点赞、评论、关注类型的系统通知流及 `unreadCount`。

#### 全部标为已读
- **URL**: `PUT /api/notifications/read`
- **Headers**: `Authorization: Bearer <token>`

#### 查询实时未读消息数
- **URL**: `GET /api/notifications/unread-count`
- **Headers**: `Authorization: Bearer <token>`

---

### 7. 全局综合搜索 (`/api/search`)

#### 联合搜索 (战报、钓点、用户)
- **URL**: `GET /api/search?q=千岛湖&type=all`
- **Query Parameters**:
  - `q`: 搜索关键词
  - `type`: `all` | `catches` | `spots` | `users`

---

### 8. 水文气象与出钓指数 (`/api/weather`)
- **URL**: `GET /api/weather?lat=30.244&lng=120.145`
- **Response**: 返回当前实时气压（hPa）、气温、风向风力、湿度、24小时逐时气压曲线及综合出钓咬口建议。

---

## 三、部署与运行指南

### 1. 本地原生直接运行
```bash
cd fisherman_server
npm install
npm start
# 服务将在 http://localhost:8080 启动
```

### 2. 自动化测试套件
```bash
cd fisherman_server
npm test
# 执行 7 个内置自动化集成测试
```

### 3. Docker 容器化运行
```bash
cd fisherman_server
# 构建镜像
docker build -t fisherman-server:1.0.0 .

# 启动容器并挂载数据持久化卷
docker run -d -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/public/uploads:/app/public/uploads \
  --name fisherman_server \
  fisherman-server:1.0.0
```

### 4. Docker Compose 一键启动
```bash
cd fisherman_server
docker-compose up -d
```
