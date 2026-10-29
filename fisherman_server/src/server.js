const app = require('./app');

const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`===============================================`);
  console.log(`🎣 钓鱼佬 (FisherMan) 服务端已成功启动!`);
  console.log(`📡 本地监听: http://localhost:${PORT}`);
  console.log(`🌐 网络监听: http://${HOST}:${PORT}`);
  console.log(`❤️  健康检查: http://localhost:${PORT}/health`);
  console.log(`===============================================`);
});
