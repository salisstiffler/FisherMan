const test = require('node:test');
const assert = require('node:assert/strict');
const weatherController = require('../src/controllers/weather');

const responseRecorder = () => ({
  statusCode: 200,
  body: null,
  status(code) {
    this.statusCode = code;
    return this;
  },
  json(body) {
    this.body = body;
    return this;
  },
});

test('weather controller maps live provider data into app forecast fields', async (t) => {
  const now = new Date();
  const hourlyTimes = Array.from({ length: 72 }, (_, index) => (
    new Date(now.getTime() + index * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 16)
  ));
  const days = [0, 1, 2].map((offset) => {
    const date = new Date(now.getTime() + offset * 24 * 60 * 60 * 1000);
    return date.toISOString().slice(0, 10);
  });
  t.mock.method(global, 'fetch', async () => ({
    ok: true,
    json: async () => ({
      current: {
        time: hourlyTimes[0],
        temperature_2m: 22.4,
        relative_humidity_2m: 61,
        pressure_msl: 1014.2,
        wind_speed_10m: 8.3,
        wind_direction_10m: 90,
      },
      hourly: {
        time: hourlyTimes,
        temperature_2m: hourlyTimes.map(() => 20),
        pressure_msl: hourlyTimes.map(() => 1014),
        precipitation_probability: hourlyTimes.map(() => 5),
      },
      daily: {
        time: days,
        temperature_2m_min: [16, 17, 15],
        temperature_2m_max: [24, 25, 22],
        precipitation_probability_max: [5, 10, 20],
      },
    }),
  }));
  const res = responseRecorder();

  await weatherController.getFishingWeather(
    { query: { lat: '31.2', lng: '121.5' } },
    res,
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.source, 'Open-Meteo');
  assert.equal(res.body.data.location.lat, 31.2);
  assert.match(res.body.data.pressure, /1014\.2 hPa/);
  assert.equal(res.body.data.hourlyForecast.length, 8);
  assert.equal(res.body.data.dailyForecast.length, 3);
});

test('weather controller rejects invalid coordinates before contacting provider', async (t) => {
  t.mock.method(global, 'fetch', async () => {
    throw new Error('fetch should not be called');
  });
  const res = responseRecorder();

  await weatherController.getFishingWeather({ query: { lat: '100' } }, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.code, 400);
  assert.equal(res.body.data, null);
});

test('weather controller reports upstream failures instead of returning fake forecasts', async (t) => {
  t.mock.method(global, 'fetch', async () => ({ ok: false, status: 503 }));
  const res = responseRecorder();

  await weatherController.getFishingWeather({ query: {} }, res);

  assert.equal(res.statusCode, 502);
  assert.equal(res.body.code, 502);
  assert.equal(res.body.data, null);
});
