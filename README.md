# 星趣App - Flutter版本

星趣App是一个基于Flutter开发的故事分享社交平台，支持iOS和Android双平台，用户可以通过手机号或微信登录，浏览、发布、点赞、评论和分享故事。

---

## 项目概述

星趣App是一个故事分享社交平台，用户可以：
- 手机号+验证码登录
- 微信快速登录
- 浏览故事广场
- 点赞、评论、分享故事
- 关注其他用户

## 技术栈

- **Flutter** 3.0+
- **Dart** 3.0+
- **数据库**: Supabase (PostgreSQL + 实时功能)
- **认证**: Supabase Auth (OTP + OAuth)
- **状态管理**: Provider
- **网络请求**: Dio + HTTP
- **图片缓存**: cached_network_image
- **图标库**: font_awesome_flutter
- **本地存储**: shared_preferences

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── config/
│   └── supabase_config.dart # Supabase配置
├── services/
│   ├── auth_service.dart    # 认证服务
│   └── story_service.dart   # 故事数据服务
├── theme/
│   └── app_theme.dart       # 主题配置（颜色、字体、样式）
├── pages/                   # 所有页面文件
├── widgets/                 # 复用组件
├── models/                  # 数据模型
└── database_schema.sql      # 数据库表结构
```

> 注：已彻底移除 web、macos、linux、windows 等无关平台目录，仅保留 iOS/Android 相关内容。

## 设计特色

- 深色主题，金色主色调
- 渐变视觉效果
- iOS风格界面
- 动画交互体验
- 实时数据同步
- 安全认证与数据持久化

## Supabase配置

### 数据库设置

1. 创建Supabase项目，获取URL和API密钥
2. 配置数据库表（见 database_schema.sql）
3. 启用手机号认证（OTP）和RLS策略
4. 配置存储桶（如 avatars、story-images）

### 环境变量配置

建议使用环境变量管理敏感信息：

```bash
export SUPABASE_URL="your-project-url"
export SUPABASE_ANON_KEY="your-anon-key"
```

或在 `--dart-define` 中传递：
```bash
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

## 快速开始

### 环境要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- iOS Simulator / Android Emulator
- 或真机设备

### 安装步骤

1. 克隆项目
   ```bash
   git clone <repository-url>
   cd xinqu_app
   ```
2. 安装依赖
   ```bash
   flutter pub get
   ```
3. 运行项目
   ```bash
   # iOS模拟器
   flutter run -d ios
   # Android模拟器
   flutter run -d android
   ```

## 开发规范

- 代码注释率≥30%，使用Dart文档注释格式
- 所有函数参数必须声明类型
- 文件命名采用snake_case，页面文件以`_page.dart`结尾
- 组件拆分遵循单一职责原则
- 合理使用StatefulWidget和StatelessWidget

## 注意事项

1. Supabase配置需正确，RLS策略需开启
2. 生产环境建议用环境变量管理API密钥
3. 图片资源建议用Supabase Storage
4. 字体文件需添加到assets目录
5. 状态管理可根据项目规模升级到Riverpod或Bloc
6. 建议添加单元测试和集成测试
7. 合理使用分页和缓存优化性能
8. 遵循Supabase最佳实践，保护用户数据

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 发起Pull Request

## 许可证

MIT License 