// Fishing weather & barometric pressure simulation engine
exports.getFishingWeather = (req, res) => {
  const lat = parseFloat(req.query.lat) || 30.274;
  const lng = parseFloat(req.query.lng) || 120.155;

  // Realistic simulation based on time of day
  const hour = new Date().getHours();
  const basePressure = 1012; // hPa
  // Pressure oscillation slightly throughout day
  const currentPressure = Math.round((basePressure + Math.sin(hour / 3.8) * 3.5) * 10) / 10;
  const temperature = Math.round(18 + Math.sin((hour - 8) / 3.8) * 6);
  const humidity = Math.round(65 + Math.cos(hour / 3.8) * 15);
  const windSpeed = '2-3级 微风';
  const windDirection = '东南风';

  // Fishing condition index
  let fishingScore = 85;
  let fishingStatus = '适宜垂钓';
  let advice = '气压平稳适中，水溶氧量良好。适合选择铧尖、深浅交界处作钓。';

  if (currentPressure >= 1010 && currentPressure <= 1016) {
    fishingScore = 92;
    fishingStatus = '爆护指数极高';
    advice = '黄金气压区间！鱼类觅食极度活跃，开口强烈，抓紧出钓！';
  } else if (currentPressure < 1005) {
    fishingScore = 45;
    fishingStatus = '鱼口偏慢';
    advice = '低气压水体缺氧，鱼浮头不开口。建议钓浮、找活水或草区。';
  }

  // 24-hour forecast curve
  const hourlyForecast = [];
  for (let i = 0; i < 24; i += 3) {
    const h = (hour + i) % 24;
    const p = Math.round((basePressure + Math.sin(h / 3.8) * 3.5) * 10) / 10;
    const t = Math.round(18 + Math.sin((h - 8) / 3.8) * 6);
    let biteIndex = '高';
    if (h >= 5 && h <= 9) biteIndex = '爆护';
    else if (h >= 17 && h <= 21) biteIndex = '极佳';
    else if (h >= 11 && h <= 15) biteIndex = '中等';

    hourlyForecast.push({
      time: `${h.toString().padStart(2, '0')}:00`,
      temperature: `${t}°C`,
      pressure: `${p} hPa`,
      biteIndex,
    });
  }

  res.json({
    code: 200,
    data: {
      location: { lat, lng },
      temperature: `${temperature}°C`,
      pressure: `${currentPressure} hPa`,
      humidity: `${humidity}%`,
      wind: `${windDirection} ${windSpeed}`,
      fishingScore,
      fishingStatus,
      advice,
      hourlyForecast,
    },
  });
};
