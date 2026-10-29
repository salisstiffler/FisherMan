# 🎣「钓鱼佬」(FisherMan) 上架发布全流程实战清单

本文档为「钓鱼佬」跨平台移动客户端（Android / iOS / Web）提供完整的生产上架发布标准作业程序（SOP），涵盖资质准备、证书签名、权限隐私合规、平台打包命令及常见应用商店审核避坑指南。

---

## 目录
1. [上架前置资质与材料准备](#一上架前置资质与材料准备)
2. [Android 生产打包与签名指南](#二android-生产打包与签名指南)
3. [iOS 生产打包与隐私清单配置](#三ios-生产打包与隐私清单配置)
4. [应用市场素材与文案规格](#四应用市场素材与文案规格)
5. [合规与审核避坑指南 (防拒审)](#五合规与审核避坑指南-防拒审)

---

## 一、上架前置资质与材料准备

### 1. 国内主流应用市场（华为应用市场、小米应用商店、腾讯应用宝、OPPO/vivo、苹果中国区）
- [ ] **APP 备案**：依据工业和信息化部要求，App 必须完成工信部 ICP 备案，在打包时填入对应的备案号（如：`浙ICP备xxxxxx号-1A`）。
- [ ] **计算机软件著作权登记证书 (软著)**：软件名称需与 App 保持一致（「钓鱼佬移动应用软件」）。
- [ ] **隐私政策与用户协议**：独立公网访问的 URL（可直接部署 `docs/PRIVACY_POLICY.md` 静态页面）。
- [ ] **测试账号与说明**：提供带完整钓点与渔获记录的预设账号（如 `diaoyu1 / 123456`），供审核人员直接体验。

### 2. 国际应用市场（Google Play / Apple App Store 海外区）
- [ ] **DUNS 邓白氏编码**（组织开发者账号必须）。
- [ ] **数据安全表单 (Google Play Data Safety) / App Privacy (App Store)**。

---

## 二、Android 生产打包与签名指南

### 1. 生成生产 Keystore 密钥库
在终端中执行以下命令（请妥善备份密钥库文件和别名密码）：
```bash
keytool -genkey -v -keystore fisherman-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fisherman \
  -storetype JKS
```

### 2. 配置 key.properties
在 `fisherman_app/android/key.properties` 中创建凭证（该文件切勿提交至公开 Git 仓库）：
```properties
storePassword=您的密钥库密码
keyPassword=您的别名密码
keyAlias=fisherman
storeFile=../fisherman-release.jks
```

### 3. 配置 build.gradle.kts / build.gradle
在 `fisherman_app/android/app/build.gradle.kts` 中添加签名配置：
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

### 4. 生产构建打包命令
```bash
# 切换至应用工程目录
cd fisherman_app

# 1. 构建 Google Play 专用 App Bundle (AAB)
flutter build appbundle --release --obfuscate --split-debug-info=./debug_symbols

# 2. 构建国内安卓渠道通用 APK (支持 64 位拆分架构优化体积)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./debug_symbols

# 产物输出路径：
# build/app/outputs/bundle/release/app-release.aab
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 三、iOS 生产打包与隐私清单配置

### 1. Info.plist 权限描述文案（针对钓鱼场景精准说明）
在 `fisherman_app/ios/Runner/Info.plist` 中添加：
```xml
<!-- 定位权限：用于推荐周边钓点、标记新钓点经纬度与水域气压测算 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>钓鱼佬需要获取您的位置权限，以便为您推荐周围最佳钓点水域、测算本地气压钓鱼指数以及标记钓点坐标。</string>

<!-- 相机权限：用于实地拍摄大鱼渔获与钓点环境照片 -->
<key>NSCameraUsageDescription</key>
<string>钓鱼佬需要使用相机，以便您实时拍摄渔获照片并发布战报分享给钓友。</string>

<!-- 相册权限：用于上传已拍摄的渔获战报图片 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>钓鱼佬需要访问您的相册，以便您挑选并上传大鱼实拍与标点照片。</string>
```

### 2. iOS 17+ 隐私清单配置 (PrivacyInfo.xcprivacy)
在 `ios/Runner/PrivacyInfo.xcprivacy` 中声明收集的数据类别（NSPrivacyCollectedDataTypeLocation、NSPrivacyCollectedDataTypePhotos）。

### 3. iOS Archive 构建命令
```bash
cd fisherman_app
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

---

## 四、应用市场素材与文案规格

| 素材类型 | 建议尺寸 / 格式 | 说明 |
| :--- | :--- | :--- |
| **应用图标 (App Icon)** | 1024 × 1024 px (PNG, 32位无透明度) | 绿金配色、钓鱼/鱼跃矢量标志 |
| **应用截图 (手机端)** | 1242 × 2688 px 或 1080 × 2400 px | 建议 4~5 张：<br>1. 钓点地图标点探索<br>2. 气压水文出钓指数<br>3. 渔获战报荣耀发布<br>4. 钓友互动与大鱼榜单 |
| **顶部大图/宣传图** | 1024 × 500 px (Google Play/华为特约) | 户外水天一色、挥竿破水场景 |
| **应用一句话简介** | 20 字以内 | `找钓点、看气压、晒大鱼，百万钓鱼佬的掌上出钓神器！` |
| **应用描述关键词** | 100 字以内 | `钓鱼,钓点,路亚,台钓,野钓,千岛湖,水库,气压,咬口指数,渔获,大鱼战报,钓鱼社区` |

---

## 五、合规与审核避坑指南 (防拒审)

1. **隐私政策弹窗首屏强制提示**：
   - App 首次冷启动时，严禁在用户点击同意《隐私政策》前静默获取用户 GPS 定位或设备标识符（已在客户端底层架构中确保遵守）。
2. **账号注销通道闭环**：
   - 依据《个人信息保护法》，App 个人设置页已配备明确的账号注销/数据清空通道。
3. **UGC 内容安全审核机制**：
   - 钓友发布的动态、评论与钓点图片，在入库时已支持字符过滤与内容巡检接口，防止违规内容。
4. **离线/弱网兜底机制**：
   - 客户端具备内置离线标点与样本动态兜底，即便审核人员处于弱网或内网沙盒环境，也不会出现空白死机或加载崩溃。
