const OPEN_METEO_URL = 'https://api.open-meteo.com/v1/forecast';
const PRESSURE_OPTIMUM = 1013;

const directionFor = (degrees) => {
  const directions = [
    '北风',
    '东北风',
    '东风',
    '东南风',
    '南风',
    '西南风',
    '西风',
    '西北风',
  ];
  return directions[Math.round(degrees / 45) % directions.length];
};

const scoreFor = (pressure, precipitationChance = 0) => {
  const pressurePenalty = Math.min(Math.abs(pressure - PRESSURE_OPTIMUM) * 5, 50);
  return Math.max(20, Math.min(98, Math.round(98 - pressurePenalty - precipitationChance * 0.35)));
};

const fishingStatusFor = (score) => {
  if (score >= 85) return '鱼口极佳';
  if (score >= 70) return '适宜垂钓';
  if (score >= 50) return '鱼口一般';
  return '鱼口偏慢';
};

exports.getFishingWeather = async (req, res) => {
  const lat = Number(req.query.lat ?? 30.274);
  const lng = Number(req.query.lng ?? 120.155);
  if (!Number.isFinite(lat) || lat < -90 || lat > 90 ||
      !Number.isFinite(lng) || lng < -180 || lng > 180) {
    return res.status(400).json({
      code: 400,
      message: '经纬度无效',
      data: null,
    });
  }

  const params = new URLSearchParams({
    latitude: String(lat),
    longitude: String(lng),
    current: [
      'temperature_2m',
      'relative_humidity_2m',
      'pressure_msl',
      'wind_speed_10m',
      'wind_direction_10m',
    ].join(','),
    hourly: [
      'temperature_2m',
      'pressure_msl',
      'precipitation_probability',
    ].join(','),
    daily: [
      'temperature_2m_max',
      'temperature_2m_min',
      'precipitation_probability_max',
    ].join(','),
    forecast_days: '3',
    timezone: 'auto',
  });

  try {
    const response = await fetch(`${OPEN_METEO_URL}?${params}`);
    if (!response.ok) {
      console.error(`Open-Meteo returned HTTP ${response.status}`);
      return res.status(502).json({
        code: 502,
        message: '天气服务暂不可用，请稍后重试',
        data: null,
      });
    }

    const forecast = await response.json();
    const current = forecast.current;
    const hourly = forecast.hourly;
    const daily = forecast.daily;
    if (!current || !hourly || !daily) {
      console.error('Open-Meteo response is missing forecast fields');
      return res.status(502).json({
        code: 502,
        message: '天气服务返回的数据不完整',
        data: null,
      });
    }

    const currentPressure = Number(current.pressure_msl);
    const score = scoreFor(currentPressure);
    const now = new Date(current.time).getTime();
    const hourlyForecast = hourly.time
      .map((time, index) => ({ time, index }))
      .filter(({ time, index }) => (
        new Date(time).getTime() >= now && index % 3 === 0
      ))
      .slice(0, 8)
      .map(({ time, index }) => {
        const hourScore = scoreFor(
          Number(hourly.pressure_msl[index]),
          Number(hourly.precipitation_probability[index] ?? 0),
        );
        return {
          time: time.slice(11, 16),
          temperature: `${Math.round(Number(hourly.temperature_2m[index]))}°C`,
          pressure: `${Number(hourly.pressure_msl[index]).toFixed(1)} hPa`,
          biteIndex: hourScore >= 85 ? '极佳' : hourScore >= 65 ? '适宜' : '偏弱',
        };
      });

    const dailyForecast = daily.time.map((day, index) => {
      const dayPressure = hourly.pressure_msl
        .filter((_, hourIndex) => hourly.time[hourIndex].startsWith(day))
        .map(Number);
      const averagePressure = dayPressure.length
        ? dayPressure.reduce((sum, value) => sum + value, 0) / dayPressure.length
        : currentPressure;
      const dayScore = scoreFor(
        averagePressure,
        Number(daily.precipitation_probability_max[index] ?? 0),
      );
      return {
        day: index === 0 ? '今天' : index === 1 ? '明天' : '后天',
        tempRange: `${Math.round(Number(daily.temperature_2m_min[index]))}°C ~ ${Math.round(Number(daily.temperature_2m_max[index]))}°C`,
        pressureRange: `${averagePressure.toFixed(0)} hPa`,
        fishingScore: dayScore,
        status: fishingStatusFor(dayScore),
      };
    });

    return res.json({
      code: 200,
      data: {
        location: { lat, lng },
        temperature: `${Math.round(Number(current.temperature_2m))}°C`,
        pressure: `${currentPressure.toFixed(1)} hPa`,
        humidity: `${Math.round(Number(current.relative_humidity_2m))}%`,
        wind: `${directionFor(Number(current.wind_direction_10m))} ${Number(current.wind_speed_10m).toFixed(1)} km/h`,
        fishingScore: score,
        fishingStatus: fishingStatusFor(score),
        advice: '指数根据实时气压与降水概率估算；出钓前请结合当地水情和安全提示。',
        hourlyForecast,
        dailyForecast,
        source: 'Open-Meteo',
      },
    });
  } catch (error) {
    console.error('Weather provider request failed:', error);
    return res.status(502).json({
      code: 502,
      message: '天气服务连接失败，请稍后重试',
      data: null,
    });
  }
};
