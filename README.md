# 星趣App (XingQu) 🌟

<div align="center">

![Star](https://img.shields.io/github/stars/joshua23/XingQu?style=social)
![Fork](https://img.shields.io/github/forks/joshua23/XingQu?style=social)
![Issues](https://img.shields.io/github/issues/joshua23/XingQu)
![License](https://img.shields.io/github/license/joshua23/XingQu)

**一个基于Flutter + Supabase的AI驱动内容创作平台**

*让每个人都能轻松创造和分享AI内容*

[🚀 快速开始](#-快速开始) • 
[📱 功能特性](#-功能特性) • 
[🛠️ 技术架构](#️-技术架构) • 
[📋 部署指南](#-部署指南) • 
[🤝 贡献指南](#-贡献指南)

</div>

---

## 📱 功能特性

### 🎯 **核心功能**
- **🤖 AI角色系统** - 创建和管理个性化AI角色
- **🎵 音频内容平台** - FM电台、播客、白噪音等音频内容
- **🎨 创作中心** - 多样化内容创作工具和模板
- **🔍 智能发现** - 基于AI推荐的内容发现机制
- **💬 社交互动** - 点赞、评论、关注等社交功能

### 📱 **界面设计**
- **🌙 深色主题** - 星空渐变背景，金色主题色
- **📲 响应式布局** - 适配各种屏幕尺寸
- **🎨 现代UI** - iOS风格设计，流畅动画效果
- **♿ 无障碍访问** - 完善的可访问性支持

---

## 🛠️ 技术架构

### **前端技术栈**
- **Flutter 3.x** - 跨平台UI框架
- **Dart** - 编程语言
- **Provider** - 状态管理
- **Material Design 3** - UI设计系统

### **后端技术栈**
- **Supabase** - 后端即服务(BaaS)
- **PostgreSQL** - 数据库
- **Row Level Security** - 数据安全
- **Real-time API** - 实时数据同步

### **核心功能模块**
```
├── 用户认证系统 (手机号+OTP)
├── AI角色管理 (创建、关注、推荐)
├── 音频内容系统 (播放、统计、分类)
├── 创作中心 (项目管理、模板、协作)
├── 发现推荐 (智能推荐、搜索)
└── 社交功能 (点赞、评论、分享)
```

---

## 📋 项目结构

```
xinqu_app/
├── lib/
│   ├── config/          # 配置文件
│   │   └── supabase_config.dart
│   ├── models/          # 数据模型
│   │   ├── ai_character.dart
│   │   ├── audio_content.dart
│   │   ├── creation_item.dart
│   │   └── discovery_content.dart
│   ├── pages/           # 页面组件
│   │   ├── main_page_refactored.dart
│   │   ├── home_refactored.dart
│   │   ├── discovery_page.dart
│   │   ├── creation_center_refactored.dart
│   │   └── test_database_page.dart
│   ├── services/        # 服务层
│   │   ├── supabase_service.dart
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   ├── utils/           # 工具类
│   │   └── api_tester.dart
│   ├── widgets/         # UI组件
│   │   ├── character_card.dart
│   │   ├── channel_card.dart
│   │   └── bottom_navigation_refactored.dart
│   └── theme/           # 主题配置
│       └── app_theme.dart
├── assets/              # 静态资源
├── database_schema_enhanced.sql  # 数据库架构
├── supabase_functions.sql       # 数据库函数
└── README.md
```

---

## 🚀 快速开始

### **环境要求**
- Flutter 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Supabase账户

### **1. 克隆项目**
```bash
git clone https://github.com/joshua23/XingQu.git
cd XingQu
```

### **2. 安装依赖**
```bash
flutter pub get
```

### **3. 配置Supabase**

1. 创建Supabase项目：[app.supabase.com](https://app.supabase.com)
2. 在`lib/config/supabase_config.dart`中更新配置：

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### **4. 部署数据库**

在Supabase SQL编辑器中依次执行：
1. `database_schema_enhanced.sql` - 创建表结构
2. `supabase_functions.sql` - 创建数据库函数

### **5. 运行应用**
```bash
flutter run
```

### **6. 测试连接**
访问应用中的 `/test_database` 路由验证数据库连接。

---

## 📋 部署指南

### **开发环境部署**
1. 按照[快速开始](#-快速开始)步骤配置
2. 运行 `flutter run` 启动开发服务器
3. 访问 `/test_database` 验证功能

### **生产环境部署**

#### **Web部署**
```bash
flutter build web
# 部署到Firebase Hosting、Vercel等
```

#### **移动端部署**
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

#### **后端配置**
- 配置Supabase认证提供商
- 设置域名白名单
- 配置文件存储桶
- 启用RLS策略

---

## 🧪 测试

### **运行测试**
```bash
# 单元测试
flutter test

# 数据库连接测试
dart test_connection.dart
```

### **API测试**
使用内置的API测试工具：
```dart
import 'package:xinqu_app/utils/api_tester.dart';

// 运行完整验证
final results = await ApiTester.runFullValidation();
```

---

## 📊 功能模块详解

### **🤖 AI角色系统**
- 角色创建和个性化设置
- 角色关注和推荐机制
- 对话历史记录
- 角色评分和反馈

### **🎵 音频内容平台**
- 多格式音频支持
- 播放进度记录
- 频道订阅管理
- 播放统计分析

### **🎨 创作中心**
- 项目管理和版本控制
- 模板库和快速创作
- 协作功能
- 发布和分享

### **🔍 智能发现**
- 基于用户偏好的推荐
- 全文搜索功能
- 分类浏览
- 热门内容展示

---

## 🔧 开发指南

### **代码规范**
- 遵循 [Dart代码规范](https://dart.dev/guides/language/effective-dart)
- 使用 `dartfmt` 格式化代码
- 编写详细的注释和文档

### **Git工作流**
1. 从 `main` 分支创建特性分支
2. 提交代码并创建Pull Request
3. 代码审查通过后合并

### **数据库开发**
- 使用Supabase RLS确保数据安全
- 所有表变更需要迁移脚本
- 定期备份生产数据

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！

### **如何贡献**
1. Fork 这个项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

### **报告问题**
- 使用 [GitHub Issues](https://github.com/joshua23/XingQu/issues) 报告bugs
- 提供详细的复现步骤
- 包含错误日志和截图

---

## 📄 许可证

本项目基于 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 🙏 致谢

- [Flutter](https://flutter.dev) - 优秀的跨平台框架
- [Supabase](https://supabase.com) - 强大的后端服务
- [Material Design](https://material.io) - 精美的设计系统

---

## 📞 联系我们

- **项目维护者**: [@joshua23](https://github.com/joshua23)
- **问题反馈**: [GitHub Issues](https://github.com/joshua23/XingQu/issues)
- **讨论交流**: [GitHub Discussions](https://github.com/joshua23/XingQu/discussions)

---

<div align="center">

**⭐ 如果这个项目对您有帮助，请给我们一个Star！⭐**

Made with ❤️ by [joshua23](https://github.com/joshua23)

</div> 