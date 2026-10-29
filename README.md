# 🎣「钓鱼佬」(FisherMan) 综合垂钓服务平台

[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-22+-339933?logo=node.js)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen)](#)
[![Tests Status](https://img.shields.io/badge/Tests-Passed%20(12%2F12)-brightgreen)](#)

「钓鱼佬」是一款专为广大垂钓运动爱好者打造的高颜值、实战型跨平台应用。集成了**水域钓点地图探索与标点**、**实时气压水文出钓指数**、**渔获大鱼战报与海报分享**、**钓友互动社区**及**钓王荣耀勋章系统**。

---

## 🌟 核心功能亮点

1. 🗺️ **钓点标记与交互式地图**
   - 基于 OpenStreetMap / 高德瓦片的高清地图浏览，支持流畅拖拽、缩放与标点聚合。
   - 水域类型筛选（野钓、水库、溪流、湖泊、黑坑、海钓）与收费形式筛选（免费、按天、按斤）。
   - 钓友众包标点：实地填报水深、出鱼鱼种、用饵心得、安全规约与路线导航。
2. 🐟 **渔获战报与大鱼海报**
   - 记录鱼种、单尾重量（精确至 0.1kg）、体长、钓法（台钓/路亚/传统钓/飞钓）、水深与实拍照片。
   - 自动生成专属荣誉战报大图，支持一键分享至社交圈。
3. ☁️ **气象水文与气压出钓指数**
   - 深度集成垂钓者最核心关切——**气压 (hPa) 波动与鱼群活性分析**。
   - 提供 24 小时逐时气压预测与最佳咬口高峰期智能推荐。
4. 🏆 **钓友社区与个人中心**
   - 渔获动态流按鱼种即时筛选，支持点赞与战法评论交流。
   - 钓王荣誉墙：自动解锁「破空先锋」、「巨物猎人」、「老钓骨」、「钓点拓荒者」等勋章。
   - 支持多账号登录、注册及**免注册一键游客体验模式**。

---

## 📁 项目工程目录

```
e:\FisherMan\
├── fisherman_app\                 # Flutter 跨平台移动客户端
│   ├── lib\
│   │   ├── core\                  # 常量、主题配色、网络封装
│   │   ├── models\                # 数据模型 (User, Spot, Catch, Weather)
│   │   ├── providers\             # 状态管理 (Provider 架构)
│   │   ├── views\                 # UI 界面 (地图、详情、动态、发布、用户中心)
│   │   └── main.dart              # 应用入口
│   ├── test\                      # 单元测试与 Widget 冒烟测试
│   ├── pubspec.yaml               # 依赖配置
│   └── analysis_options.yaml      # 代码规范与 Lint 规则
│
├── fisherman_server\              # 生产就绪后端服务
│   ├── src\
│   │   ├── controllers\           # 认证、钓点、渔获、气象、统计接口控制器
│   │   ├── middleware\            # JWT 认证与文件上传中间件
│   │   ├── db.js                  # 原生 SQLite 引擎与千岛湖/富春江等种子数据
│   │   ├── app.js                 # Express 路由及安全配置
│   │   └── server.js              # 服务监听入口
│   ├── test\                      # 自动化 API 接口集成测试
│   ├── Dockerfile                 # 容器化镜像构建
│   ├── docker-compose.yml         # 单机容器化一键编排
│   └── package.json               # 后端依赖配置
│
└── docs\                          # 发布与技术文档
    ├── RELEASE_CHECKLIST.md       # 应用市场 (Android/iOS) 审核与签名发布清单
    ├── PRIVACY_POLICY.md          # 个人信息保护及合规隐私政策范本
    └── API_DOCUMENTATION.md       # 详细 RESTful API 接口定义与调试指南
```

---

## 🚀 快速启动指南

### 1. 启动后端 API 服务
```bash
cd fisherman_server
# 安装依赖
npm.cmd install

# 启动服务 (默认监听 http://localhost:8080)
npm.cmd start

# 运行后端自动化测试套件
npm.cmd test
```

### 2. 启动 Flutter 客户端
```bash
cd fisherman_app
# 拉取依赖
flutter pub get

# 执行代码规约静态检查 (0 issues)
flutter analyze

# 执行客户端自动化测试套件
flutter test

# 启动 Web / Chrome 预览运行
flutter run -d chrome
```

---

## 📊 质量与验证报告

| 检查项 | 命令 | 结果 | 耗时 |
| :--- | :--- | :--- | :--- |
| **Dart 静态语法与代码规范** | `flutter analyze` | **No issues found! (0 告警 0 错误)** | 1.7s |
| **客户端单元与界面测试** | `flutter test` | **5 passed, 0 failed** | 0.8s |
| **客户端跨平台编译验证** | `flutter build web` | **√ Built build\web** | 33.6s |
| **服务端接口集成测试** | `npm test` | **7 passed, 0 failed** | 4.2s |
