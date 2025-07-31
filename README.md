# 星趣App (XingQu) 🌟

<div align="center">

![Star](https://img.shields.io/github/stars/joshua23/XingQu?style=social)
![Fork](https://img.shields.io/github/forks/joshua23/XingQu?style=social)
![Issues](https://img.shields.io/github/issues/joshua23/XingQu)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**基于Flutter + Supabase的AI驱动内容创作平台**

*让每个人都能轻松创造和分享AI内容*

[🚀 快速开始](#-快速开始) • 
[📱 功能展示](#-功能展示) • 
[🛠️ 技术架构](#️-技术架构) • 
[📋 部署指南](#-部署指南) • 
[🤝 参与贡献](#-参与贡献)

</div>

---

## 📱 功能展示

### 🎯 **核心功能模块**

#### **🏠 主页系统 - 4个专业Tab**
- **📊 精选页**: AI角色展示、轮播推荐、个性化内容
- **🎭 综合页**: 6大功能模块、快速入口、动态内容
- **🎵 FM电台**: 音频播放器、频道管理、播放历史、实时统计
- **🤖 AI助理**: 宇宙背景、AI交互、预设问题、系统功能

#### **🔍 发现中心**
- **智能搜索**: 全文搜索、分类筛选、实时建议
- **精选内容**: 热门推荐、分类导航、用户评分
- **创作展示**: 用户作品、模板资源、学习教程

#### **🎨 创作中心**
- **多种模式**: AI角色创作、音频制作、故事编写、游戏设计
- **快速工具**: 模板库、素材管理、预览功能
- **项目管理**: 草稿保存、版本控制、协作分享

#### **🤖 AI角色系统**
- **角色创建**: 个性化设置、性格定义、背景故事
- **互动功能**: 实时对话、情感反馈、学习成长
- **社交特性**: 关注收藏、评分评论、分享传播

#### **🎵 音频内容平台**
- **播放系统**: 高音质播放、进度控制、循环模式
- **内容管理**: 分类浏览、收藏列表、播放历史
- **社区功能**: 用户上传、评论互动、推荐算法

---

## 🛠️ 技术架构

### **前端技术栈**
```yaml
Framework: Flutter 3.x
Language: Dart 3.0+
UI Design: Material Design 3
State Management: Provider
Navigation: Named Routes + PageView
Animations: Built-in + Lottie
Icons: FontAwesome + Cupertino
```

### **后端技术栈**
```yaml
Backend Service: Supabase
Database: PostgreSQL with Extensions
Authentication: OTP + OAuth
File Storage: Supabase Storage
Real-time: WebSocket
Security: Row Level Security (RLS)
```

### **项目架构图**
```
┌─────────────────────────────────────────────┐
│                  Flutter App                │
├─────────────────────────────────────────────┤
│  UI Layer (Pages + Widgets + Theme)        │
│  ├── MainPageRefactored (5 main pages)     │
│  ├── HomeRefactored (4 tabs)               │
│  ├── DiscoveryPage (search + content)      │
│  ├── CreationCenterRefactored              │
│  └── TestDatabasePage (dev tools)          │
├─────────────────────────────────────────────┤
│  Business Logic Layer                      │
│  ├── ApiService (business APIs)            │
│  ├── SupabaseService (database ops)        │
│  ├── AuthService (authentication)          │
│  └── ApiTester (testing utilities)         │
├─────────────────────────────────────────────┤
│  Data Layer                                │
│  ├── Models (AICharacter, AudioContent)    │
│  ├── Providers (state management)          │
│  └── Local Storage (SharedPreferences)     │
├─────────────────────────────────────────────┤
│              Supabase Backend              │
│  ├── PostgreSQL Database (15 tables)       │
│  ├── Authentication (OTP + OAuth)          │
│  ├── Storage (files + media)               │
│  ├── Real-time (WebSocket)                 │
│  └── Edge Functions (custom logic)         │
└─────────────────────────────────────────────┘
```

---

## 📋 项目结构

```
xinqu_app/
├── lib/
│   ├── main.dart                    # 应用入口点
│   ├── config/                      # 配置文件
│   │   └── supabase_config.dart     # Supabase连接配置
│   ├── models/                      # 数据模型
│   │   ├── ai_character.dart        # AI角色数据模型
│   │   ├── audio_content.dart       # 音频内容模型
│   │   ├── creation_item.dart       # 创作项目模型
│   │   ├── discovery_content.dart   # 发现内容模型
│   │   └── story.dart               # 故事数据模型
│   ├── pages/                       # 页面文件
│   │   ├── main_page_refactored.dart      # 主页面容器
│   │   ├── home_refactored.dart           # 重构后首页
│   │   ├── home_tabs/                     # 首页Tab页面
│   │   │   ├── home_selection_page.dart   # 精选页
│   │   │   ├── home_comprehensive_page.dart # 综合页  
│   │   │   ├── home_fm_page.dart          # FM电台页
│   │   │   └── home_assistant_page.dart   # AI助理页
│   │   ├── discovery_page.dart            # 发现页面
│   │   ├── creation_center_refactored.dart # 创作中心
│   │   ├── test_database_page.dart        # 数据库测试页
│   │   ├── login_page.dart                # 登录页面
│   │   └── splash_page.dart               # 启动页面
│   ├── services/                    # 服务层
│   │   ├── supabase_service.dart    # Supabase底层服务
│   │   ├── api_service.dart         # 业务API服务
│   │   ├── auth_service.dart        # 认证服务
│   │   └── story_service.dart       # 故事服务
│   ├── utils/                       # 工具类
│   │   └── api_tester.dart          # API测试工具
│   ├── widgets/                     # UI组件
│   │   ├── character_card.dart      # AI角色卡片
│   │   ├── channel_card.dart        # 音频频道卡片
│   │   ├── bottom_navigation_refactored.dart # 底部导航
│   │   ├── audio_player_widget.dart # 音频播放器组件
│   │   └── starry_background.dart   # 星空背景组件
│   ├── theme/                       # 主题配置
│   │   └── app_theme.dart           # 应用主题定义
│   └── providers/                   # 状态管理
│       └── auth_provider.dart       # 认证状态管理
├── assets/                          # 静态资源
│   └── images/logo.png              # 应用Logo
├── android/                         # Android配置
├── ios/                            # iOS配置
├── database_schema_enhanced.sql     # 增强版数据库架构
├── supabase_functions.sql          # 数据库函数和触发器
├── test_connection.dart            # 数据库连接测试脚本
├── pubspec.yaml                    # Flutter项目配置
└── README.md                       # 项目说明文档
```

---

## 🚀 快速开始

### **环境要求**
- **Flutter SDK**: 3.0+ 
- **Dart SDK**: 3.0+
- **开发工具**: Android Studio / VS Code
- **平台支持**: iOS 11+, Android 5.0+
- **后端服务**: Supabase账户

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

#### 创建Supabase项目
1. 访问 [Supabase](https://app.supabase.com) 并创建新项目
2. 记录项目URL和匿名密钥

#### 更新配置文件
在 `lib/config/supabase_config.dart` 中更新：
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### **4. 部署数据库**

在Supabase SQL编辑器中依次执行：

#### 创建数据库架构
```sql
-- 复制并执行 database_schema_enhanced.sql 内容
-- 创建15个核心表：users, ai_characters, audio_contents 等
```

#### 添加数据库函数
```sql
-- 复制并执行 supabase_functions.sql 内容  
-- 添加触发器、计数器、搜索功能等
```

#### 配置存储桶
```sql
-- 创建文件存储桶
INSERT INTO storage.buckets (id, name, public) VALUES 
('avatars', 'avatars', true),
('audios', 'audios', true),
('thumbnails', 'thumbnails', true);
```

### **5. 运行应用**
```bash
# 开发模式
flutter run

# 指定设备
flutter run -d ios
flutter run -d android

# Web版本
flutter run -d web
```

### **6. 验证部署**
启动应用后，访问测试页面验证功能：
- 在应用中导航到"数据库测试"页面
- 或直接访问路由：`/test_database`
- 查看控制台输出确认连接状态

---

## 🧪 测试和验证

### **数据库连接测试**
使用内置测试工具验证后端连接：
```dart
import 'package:xinqu_app/utils/api_tester.dart';

// 运行完整验证
final results = await ApiTester.runFullValidation();

// 检查特定功能
final dbConnected = await ApiTester.testDatabaseConnection();
final apiWorking = await ApiTester.testAPIFunctions();
```

### **命令行测试**
```bash
# 运行数据库连接测试
dart test_connection.dart

# 运行Flutter测试
flutter test

# 生成覆盖率报告
flutter test --coverage
```

### **测试内容包括**
- ✅ 数据库连接和表结构验证
- ✅ API服务功能测试
- ✅ 用户认证流程测试
- ✅ 数据CRUD操作测试
- ✅ 文件上传和存储测试

---

## 📱 部署指南

### **开发环境**
推荐配置：
```bash
# 检查Flutter环境
flutter doctor

# 配置IDE
flutter config --enable-web
flutter config --enable-macos-desktop
```

### **生产部署**

#### **移动端发布**
```bash
# Android发布
flutter build apk --release
flutter build appbundle --release

# iOS发布  
flutter build ios --release
```

#### **Web端部署**
```bash
# 构建Web版本
flutter build web --release

# 部署到Firebase Hosting
firebase deploy

# 或部署到Vercel
vercel --prod
```

#### **后端配置**
1. **认证设置**：配置手机号认证和OAuth提供商
2. **域名配置**：设置允许的域名白名单
3. **存储配置**：创建和配置文件存储桶
4. **安全策略**：启用RLS和访问控制

---

## 🎨 设计系统

### **视觉特色**
- **🌙 深色主题**：星空渐变背景，科技感十足
- **🌟 金色主调**：#FFD700主色调，高级质感
- **🎭 iOS风格**：现代化设计语言，流畅交互
- **✨ 动画效果**：微交互动画，提升用户体验

### **组件库**
- **CharacterCard**：AI角色展示卡片
- **ChannelCard**：音频频道卡片，带动画效果
- **AudioPlayerWidget**：专业音频播放控件
- **StarryBackground**：动态星空背景组件

---

## 📊 功能详解

### **🤖 AI角色系统**
```dart
// AI角色数据模型
class AICharacter {
  final String id;
  final String name;
  final String personality;
  final String description;
  final List<String> tags;
  final bool isFollowing;
  final int followerCount;
  // ... 更多属性
}

// 使用示例
final characters = await ApiService.instance.getAICharacters();
await ApiService.instance.toggleCharacterFollow(characterId);
```

### **🎵 音频内容系统**
```dart
// 音频内容模型
class AudioContent {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String category;
  final int playCount;
  // ... 播放和统计信息
}

// 播放记录
await ApiService.instance.recordAudioPlay(
  audioId: audioId,
  playPosition: 30,
  completed: false,
);
```

### **🎨 创作中心**
```dart
// 创作项目模型
class CreationItem {
  final String id;
  final String title;
  final String contentType;
  final String status;
  final DateTime lastModified;
  // ... 项目管理信息
}

// 创建项目
final projectId = await ApiService.instance.createCreationItem(
  title: "我的AI角色",
  contentType: "character",
  description: "一个有趣的AI角色",
);
```

---

## 🔧 开发指南

### **代码规范**
- 遵循 [Dart官方代码规范](https://dart.dev/guides/language/effective-dart)
- 使用 `dartfmt` 自动格式化代码
- 编写详细的注释和文档字符串
- 函数和类命名使用驼峰命名法

### **项目结构规范**
- `pages/` - 页面级组件，负责整体布局
- `widgets/` - 可复用UI组件
- `services/` - 业务逻辑和API调用
- `models/` - 数据模型定义
- `utils/` - 工具函数和辅助类

### **Git工作流**
```bash
# 创建功能分支
git checkout -b feature/your-feature-name

# 提交代码
git add .
git commit -m "✨ 添加新功能: 描述"

# 推送并创建PR
git push origin feature/your-feature-name
```

---

## 🤝 参与贡献

我们欢迎所有形式的贡献！

### **贡献方式**
1. **🐛 报告Bug**：在 [Issues](https://github.com/joshua23/XingQu/issues) 中提交bug报告
2. **💡 功能建议**：提出新功能想法和改进建议  
3. **📖 文档改进**：完善文档和示例代码
4. **🔧 代码贡献**：提交功能代码和bug修复

### **贡献步骤**
1. Fork本项目到您的GitHub账户
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

### **贡献规范**
- 提交信息使用约定式提交格式
- 添加适当的测试覆盖
- 更新相关文档
- 确保代码通过所有检查

---

## 📈 项目状态

### **开发进度**
- ✅ **前端UI系统**: 95% 完成
- ✅ **后端API架构**: 100% 完成  
- ✅ **数据库设计**: 100% 完成
- ✅ **测试工具**: 100% 完成
- ✅ **部署文档**: 100% 完成

### **已实现功能**
- ✅ 完整的页面导航和路由系统
- ✅ AI角色创建、展示和交互功能
- ✅ 音频播放器和内容管理系统  
- ✅ 创作中心和项目管理功能
- ✅ 发现页面和智能推荐系统
- ✅ 用户认证和权限管理
- ✅ 数据库连接和API测试工具

### **技术亮点**
- 🏗️ **现代化架构**：Flutter + Supabase全栈解决方案
- 🎨 **精美UI设计**：深色主题 + 星空背景 + 流畅动画
- 🔒 **企业级安全**：RLS行级安全 + OAuth认证
- 🧪 **完善测试**：自动化测试工具和验证系统
- 📚 **详细文档**：完整的开发和部署指南

---

## 📞 联系我们

- **👨‍💻 项目维护者**: [@joshua23](https://github.com/joshua23)
- **🐛 问题反馈**: [GitHub Issues](https://github.com/joshua23/XingQu/issues)
- **💬 讨论交流**: [GitHub Discussions](https://github.com/joshua23/XingQu/discussions)
- **📧 邮件联系**: 通过GitHub联系

---

## 📄 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

```
MIT License - 您可以自由地：
✅ 使用 - 商业或个人用途
✅ 修改 - 根据需要调整代码  
✅ 分发 - 分享给其他人
✅ 私用 - 用于私人项目
✅ 出售 - 用于商业产品
```

---

## 🙏 致谢

感谢以下优秀的开源项目和服务：

- **[Flutter](https://flutter.dev)** - 强大的跨平台UI框架
- **[Supabase](https://supabase.com)** - 现代化的Firebase替代方案
- **[Material Design](https://material.io)** - 谷歌设计系统
- **[FontAwesome](https://fontawesome.com)** - 丰富的图标库
- **[Dart](https://dart.dev)** - 高效的编程语言

---

<div align="center">

### ⭐ **如果这个项目对您有帮助，请给我们一个Star！** ⭐

**让我们一起构建更好的AI内容创作平台！**

[![Star History Chart](https://api.star-history.com/svg?repos=joshua23/XingQu&type=Date)](https://star-history.com/#joshua23/XingQu&Date)

---

**Made with ❤️ by [joshua23](https://github.com/joshua23)**

*最后更新：2024年7月31日*

</div> 