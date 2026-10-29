const test = require('node:test');
const assert = require('node:assert');
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

test('GET /api/weather returns barometric pressure & fishing score', async () => {
  const res = await fetch(`${baseUrl}/api/weather?lat=30.27&lng=120.15`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.code, 200);
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
