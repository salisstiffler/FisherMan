const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const app = require('../src/app');

// Spin up a transient test server
let server;
let baseUrl;

test.before((t, done) => {
  server = app.listen(0, '127.0.0.1', () => {
    const port = server.address().port;
    baseUrl = `http://127.0.0.1:${port}`;
    done();
  });
});

test.after((t, done) => {
  server.close(done);
});

test('GET /health returns 200 OK', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.status, 'ok');
  assert.match(data.app, /FisherMan/);
});

test('GET /api/spots returns list of seeded spots', async () => {
  const res = await fetch(`${baseUrl}/api/spots`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.ok(Array.isArray(json.data));
  assert.ok(json.data.length >= 4);
  assert.ok(json.data[0].name);
  assert.ok(json.data[0].lat);
  assert.ok(json.data[0].lng);
});

test('GET /api/catches returns list of seeded catches', async () => {
  const res = await fetch(`${baseUrl}/api/catches`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.ok(Array.isArray(json.data));
  assert.ok(json.data.length >= 3);
  assert.ok(json.data[0].fishType);
  assert.ok(json.data[0].weightKg);
});

test('GET /api/catches supports offset pagination', async () => {
  const res = await fetch(`${baseUrl}/api/catches?limit=1&offset=1`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.data.length, 1);
});

test('GET /api/weather returns barometric pressure & fishing score', async () => {
  const originalFetch = global.fetch;
  const currentTime = new Date();
  const hourlyTimes = Array.from({ length: 72 }, (_, index) => (
    new Date(currentTime.getTime() + index * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 16)
  ));
  const dailyTimes = [0, 1, 2].map((offset) => (
    new Date(currentTime.getTime() + offset * 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10)
  ));
  global.fetch = (input, init) => {
    if (String(input).startsWith('https://api.open-meteo.com/')) {
      return Promise.resolve({
        ok: true,
        json: async () => ({
          current: {
            time: hourlyTimes[0],
            temperature_2m: 20,
            relative_humidity_2m: 60,
            pressure_msl: 1012,
            wind_speed_10m: 5,
            wind_direction_10m: 90,
          },
          hourly: {
            time: hourlyTimes,
            temperature_2m: hourlyTimes.map(() => 20),
            pressure_msl: hourlyTimes.map(() => 1012),
            precipitation_probability: hourlyTimes.map(() => 0),
          },
          daily: {
            time: dailyTimes,
            temperature_2m_min: [15, 16, 17],
            temperature_2m_max: [22, 23, 24],
            precipitation_probability_max: [0, 5, 10],
          },
        }),
      });
    }
    return originalFetch(input, init);
  };
  let res;
  try {
    res = await fetch(`${baseUrl}/api/weather?lat=30.27&lng=120.15`);
  } finally {
    global.fetch = originalFetch;
  }
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.strictEqual(json.data.source, 'Open-Meteo');
  assert.ok(json.data.pressure);
  assert.ok(json.data.fishingScore >= 0);
  assert.ok(json.data.hourlyForecast.length > 0);
});

test('GET /api/stats returns angler leaderboard and total counts', async () => {
  const res = await fetch(`${baseUrl}/api/stats`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.ok(json.data.totalSpots >= 5);
  assert.ok(json.data.leaderboard.length > 0);
});

test('POST /api/auth/login with seeded user', async () => {
  const res = await fetch(`${baseUrl}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'diaoyu1', password: '123456' }),
  });
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.ok(json.data.token);
  assert.strictEqual(json.data.user.nickname, '空军总司令');
});

test('POST /api/auth/register a new angler', async () => {
  const testUser = `angler_${Date.now()}`;
  const res = await fetch(`${baseUrl}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: testUser,
      password: 'password123',
      nickname: '西湖夜钓客',
    }),
  });
  assert.strictEqual(res.status, 201);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
  assert.ok(json.data.token);
  assert.strictEqual(json.data.user.nickname, '西湖夜钓客');
});

test('social profile, notifications, and content ownership endpoints', async () => {
  async function register(username, nickname) {
    const response = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password: 'password123', nickname }),
    });
    assert.strictEqual(response.status, 201);
    return (await response.json()).data;
  }

  async function request(path, token, method = 'GET', body) {
    return fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
  }

  const suffix = Date.now();
  const owner = await register(`owner_${suffix}`, '战报作者');
  const follower = await register(`follower_${suffix}`, '关注者');

  const form = new FormData();
  form.append('file', new Blob(['test image'], { type: 'image/png' }), 'test.png');
  const uploadResponse = await fetch(`${baseUrl}/api/upload`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${owner.token}` },
    body: form,
  });
  assert.strictEqual(uploadResponse.status, 200);
  const uploadData = (await uploadResponse.json()).data;
  assert.match(uploadData.url, /^\/uploads\/fish_/);
  const uploadedFile = path.resolve(
    __dirname,
    '..',
    'public',
    uploadData.url.slice(1),
  );
  fs.unlinkSync(uploadedFile);

  const catchResponse = await request('/api/catches', owner.token, 'POST', {
    fishType: '测试鱼',
    weightKg: 1.2,
    notes: '原始备注',
  });
  assert.strictEqual(catchResponse.status, 201);
  const catchId = (await catchResponse.json()).data.id;
  const badgeProfileResponse = await request(
    `/api/users/${owner.user.id}`,
    owner.token,
  );
  const badges = (await badgeProfileResponse.json()).data.stats.badges;
  assert.equal(badges.find((badge) => badge.id === 'first_blood').unlocked, true);
  assert.equal(badges.find((badge) => badge.id === 'veteran').unlocked, false);
  assert.ok(badges.some((badge) => badge.id === 'species_collector'));
  const statsResponse = await request('/api/stats/my', owner.token);
  assert.strictEqual(statsResponse.status, 200);
  const stats = (await statsResponse.json()).data;
  assert.ok(Array.isArray(stats.monthly));
  assert.ok(Array.isArray(stats.fishDistribution));

  const followResponse = await request(
    `/api/users/${owner.user.id}/follow`,
    follower.token,
    'POST',
  );
  assert.strictEqual(followResponse.status, 200);
  assert.strictEqual((await followResponse.json()).data.isFollowing, true);

  const profileResponse = await request(
    `/api/users/${owner.user.id}`,
    follower.token,
  );
  const profile = (await profileResponse.json()).data;
  assert.strictEqual(profile.isFollowing, true);
  assert.strictEqual(profile.stats.followersCount, 1);

  assert.strictEqual(
    (await request(`/api/catches/${catchId}/like`, follower.token, 'POST')).status,
    200,
  );
  const spotListResponse = await request('/api/spots', owner.token);
  const favoriteSpotId = (await spotListResponse.json()).data[0].id;
  const favoriteOn = await request(
    `/api/spots/${favoriteSpotId}/favorite`,
    owner.token,
    'POST',
  );
  assert.equal((await favoriteOn.json()).data.isFavorited, true);
  const favorites = await request('/api/my/favorites', owner.token);
  assert.ok(
    (await favorites.json()).data.some((spot) => spot.id === favoriteSpotId),
  );
  const favoriteOff = await request(
    `/api/spots/${favoriteSpotId}/favorite`,
    owner.token,
    'POST',
  );
  assert.equal((await favoriteOff.json()).data.isFavorited, false);
  const commentResponse = await request(
    `/api/catches/${catchId}/comments`,
    follower.token,
    'POST',
    { content: '很棒的渔获' },
  );
  assert.strictEqual(commentResponse.status, 201);
  const commentId = (await commentResponse.json()).data.id;
  assert.strictEqual(
    (await request(`/api/catches/${catchId}/comments`, owner.token, 'POST', {
      content: '感谢夸奖',
      parentId: commentId,
    })).status,
    201,
  );
  const detail = await request(`/api/catches/${catchId}`, owner.token);
  const comments = (await detail.json()).data.comments;
  assert.ok(comments.some((item) => item.parentId === commentId));

  const search = await fetch(
    `${baseUrl}/api/search?q=${encodeURIComponent(owner.user.nickname)}&type=users`,
  );
  assert.strictEqual(search.status, 200);
  assert.ok((await search.json()).data.some((item) => item.id === owner.user.id));

  const notificationsResponse = await request('/api/notifications', owner.token);
  const notifications = (await notificationsResponse.json()).data;
  assert.ok(notifications.notifications.some((item) => item.type === 'follow'));
  assert.ok(notifications.notifications.some((item) => item.type === 'like'));
  assert.ok(notifications.notifications.some((item) => item.type === 'comment'));
  assert.ok(notifications.unreadCount >= 3);
  assert.strictEqual(
    (await request('/api/notifications/read', owner.token, 'PUT')).status,
    200,
  );
  assert.strictEqual(
    (await request(
      `/api/catches/${catchId}/comments/${commentId}`,
      owner.token,
      'DELETE',
    )).status,
    403,
  );
  assert.strictEqual(
    (await request(
      `/api/catches/${catchId}/comments/${commentId}`,
      follower.token,
      'DELETE',
    )).status,
    200,
  );
  const afterCommentDelete = await request(`/api/catches/${catchId}`, owner.token);
  const remainingComments = (await afterCommentDelete.json()).data.comments;
  assert.ok(remainingComments.some((item) => item.parentId === null));

  assert.strictEqual(
    (await request(`/api/catches/${catchId}`, follower.token, 'PUT', {
      notes: '未经授权修改',
    })).status,
    403,
  );
  assert.strictEqual(
    (await request(`/api/catches/${catchId}`, owner.token, 'PUT', {
      notes: '更新后的备注',
    })).status,
    200,
  );
  assert.strictEqual(
    (await request(`/api/catches/${catchId}`, follower.token, 'DELETE')).status,
    403,
  );
  assert.strictEqual(
    (await request(`/api/catches/${catchId}`, owner.token, 'DELETE')).status,
    200,
  );

  const spotResponse = await request('/api/spots', owner.token, 'POST', {
    name: '测试钓点',
    lat: 30.2,
    lng: 120.1,
  });
  assert.strictEqual(spotResponse.status, 201);
  const spotId = (await spotResponse.json()).data.id;
  assert.strictEqual(
    (await request(`/api/spots/${spotId}/reviews`, follower.token, 'POST', {
      rating: 4,
      content: '水边环境不错',
    })).status,
    200,
  );
  const reviewsResponse = await fetch(`${baseUrl}/api/spots/${spotId}/reviews`);
  const reviews = (await reviewsResponse.json()).data;
  assert.strictEqual(reviews.avgRating, 4);
  assert.strictEqual(reviews.reviews.length, 1);
  assert.strictEqual(
    (await request(`/api/spots/${spotId}`, follower.token, 'DELETE')).status,
    403,
  );
  assert.strictEqual(
    (await request(`/api/spots/${spotId}`, owner.token, 'PUT', {
      description: '更新描述',
    })).status,
    200,
  );
  assert.strictEqual(
    (await request(`/api/spots/${spotId}`, owner.token, 'DELETE')).status,
    200,
  );

  // Test Refresh Token endpoint
  const refreshRes = await fetch(`${baseUrl}/api/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken: owner.refreshToken }),
  });
  assert.strictEqual(refreshRes.status, 200);
  const refreshJson = await refreshRes.json();
  assert.strictEqual(refreshJson.code, 200);
  assert.ok(refreshJson.data.token);
  assert.ok(refreshJson.data.refreshToken);

  // Test 3-day weather forecast
  const weatherRes = await fetch(`${baseUrl}/api/weather?lat=30.25&lng=120.15`);
  assert.strictEqual(weatherRes.status, 200);
  const weatherJson = await weatherRes.json();
  assert.ok(Array.isArray(weatherJson.data.dailyForecast));
  assert.strictEqual(weatherJson.data.dailyForecast.length, 3);
});
