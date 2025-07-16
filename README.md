# 星趣App - Flutter版本

基于原型HTML文件开发的Flutter移动应用，提供故事分享平台功能。

---

## 高保真原型归档

所有高保真原型HTML文件及原型文档（如 index.html、splash.html、login.html、modao_export_outline.md 等）已统一归档至项目根目录下的 `高保真原型/` 文件夹，便于查阅和对照开发。Flutter端所有页面均严格对齐该目录下的高保真原型。

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
高保真原型/                # 高保真原型HTML及原型文档归档目录
lib/
├── main.dart                 # 应用入口
├── config/
│   └── supabase_config.dart # Supabase配置
├── services/
│   ├── auth_service.dart    # 认证服务
│   └── story_service.dart   # 故事数据服务
├── theme/
│   └── app_theme.dart       # 主题配置（颜色、字体、样式）
├── pages/                   # 所有页面文件，Flutter端高保真还原
│   ├── splash_page.dart           # 启动页（对应高保真原型 splash.html）
│   ├── login_page.dart            # 登录页（对应 login.html）
│   ├── login_error_page.dart      # 登录异常页（对应 login_error.html）
│   ├── home_page.dart             # 故事广场（对应 home.html）
│   ├── story_detail_page.dart     # 故事详情（对应 story_detail.html）
│   ├── story_search_page.dart     # 故事搜索（对应 story_search.html）
│   ├── story_share_page.dart      # 故事分享（对应 story_share.html）
│   ├── story_comment_page.dart    # 故事评论（对应 story_comment.html）
│   ├── ai_chat_page.dart          # AI虚拟聊天（对应 ai_chat.html）
│   ├── ai_chat_settings_page.dart # AI聊天设置（对应 ai_chat_settings.html）
│   ├── ai_character_manage_page.dart # AI角色管理（对应 ai_character_manage.html）
│   ├── character_create_page.dart # 角色创建（对应 character_create.html）
│   ├── creation_center_page.dart  # 创作中心（对应 creation.html）
│   ├── story_creation_page.dart   # 故事创作（对应 story_create.html）
│   ├── messages_page.dart         # 消息页（对应 messages.html）
│   ├── profile_page.dart          # 个人中心（对应 profile.html）
│   ├── settings_page.dart         # 设置页（对应 settings.html）
│   ├── wechat_auth_page.dart      # 微信授权页（对应 wechat_auth.html）
│   └── template_center_page.dart  # 模板中心（如有）
├── widgets/                  # 复用组件
├── models/                   # 数据模型
└── database_schema.sql       # 数据库表结构
```

> 注：已彻底移除 web、macos、linux、windows 等无关平台目录，仅保留 iOS/Android 相关内容。

## 设计特色

### 视觉设计
- **深色主题**: 黑色背景 + 金色主色调
- **渐变效果**: 多处使用线性渐变增强视觉效果
- **iOS风格**: 模拟iPhone界面，包含状态栏
- **动画交互**: 点赞、加载等动画效果

### 颜色规范
- 主色调: `#F5DFAF` (金色)
- 强调色: `#FF4D67` (红色)
- 辅助色: `#4251F5` (蓝色)
- 背景色: `#000000` (黑色)
- 表面色: `#1E1E1E` (深灰)

### 功能特点
- **手机号登录**: 验证码倒计时功能，基于Supabase Auth
- **故事卡片**: 支持图片、标签、点赞评论，数据实时同步
- **无限滚动**: 自动加载更多内容，分页查询优化
- **下拉刷新**: 手势刷新最新内容，从云端获取
- **浮动按钮**: 快速创建新故事，支持图片上传
- **实时功能**: 点赞、评论、关注状态实时更新
- **安全认证**: 基于JWT的用户认证和权限控制
- **数据持久化**: 云端数据存储，支持离线缓存

## Supabase配置

### 数据库设置

1. **创建Supabase项目**
   - 访问 [supabase.com](https://supabase.com)
   - 创建新项目并获取URL和API密钥

2. **配置数据库表**
   ```sql
   -- 在Supabase SQL编辑器中执行 database_schema.sql 文件
   -- 创建以下表结构：
   - users (用户表)
   - stories (故事表)  
   - tags (标签表)
   - story_tags (故事标签关联表)
   - likes (点赞表)
   - comments (评论表)
   - follows (关注表)
   ```

3. **配置认证**
   - 启用手机号认证（OTP）
   - 配置SMS提供商（Twilio等）
   - 设置行级安全策略（RLS）

4. **配置存储**
   ```bash
   # 创建存储桶
   - avatars (用户头像)
   - story-images (故事图片)
   ```

### 环境变量配置

在生产环境中，建议使用环境变量管理敏感信息：

```bash
# 设置环境变量
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

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd xinqu_app
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   ```bash
   # iOS模拟器
   flutter run -d ios
   
   # Android模拟器
   flutter run -d android
   
   # 网页版（调试用）
   flutter run -d web
   ```

## 页面展示

### 登录页面
- 精美的Logo设计（菱形旋转星形）
- 手机号+验证码登录
- 微信快速登录
- 用户协议勾选
- 输入验证和错误提示

### 首页（故事广场）
- iOS风格状态栏
- 顶部导航（搜索、通知）
- 故事卡片列表
- 底部导航（4个tab）
- 浮动发布按钮

### 启动页高保真还原
- 启动页UI已严格对齐高保真原型：
  - 品牌Logo、品牌色星形符号、主标题（“星趣”）、副标题均与原型一致。
  - 加载动画为横向渐变进度条，宽120、高8，动画宽度60%~100%循环。
  - 所有文本、配色、布局均遵循原型和品牌规范。

## 开发规范

### 代码注释
- 函数注释率: ≥30%
- 使用Dart文档注释格式
- 参数类型必须声明

### 文件命名
- 使用snake_case命名
- 页面文件以`_page.dart`结尾
- 组件文件使用描述性名称

### 组件拆分
- 单一职责原则
- 可复用组件独立封装
- 合理使用StatefulWidget和StatelessWidget

## 待实现功能

- [ ] AI聊天页面
- [ ] 消息中心页面
- [ ] 个人中心页面
- [ ] 故事创建页面（含图片上传）
- [ ] 故事详情页面
- [ ] 搜索功能（全文搜索）
- [ ] 通知系统（实时推送）
- [ ] 分享功能（第三方分享）
- [ ] 文件上传（Supabase Storage）
- [ ] 离线缓存优化
- [ ] 实时聊天功能
- [ ] 内容推荐算法
- [ ] 多语言支持
- [ ] 深色/浅色主题切换

## 注意事项

1. **Supabase配置**: 确保正确配置数据库表结构和RLS策略
2. **环境变量**: 生产环境中使用环境变量管理API密钥
3. **图片资源**: 当前使用网络图片，建议使用Supabase Storage
4. **字体文件**: 需要添加PingFang字体文件到assets目录
5. **网络请求**: 已集成Supabase，支持实时数据同步
6. **状态管理**: 可以根据项目规模升级到Riverpod或Bloc
7. **测试**: 建议添加单元测试和集成测试
8. **性能优化**: 合理使用分页和缓存策略
9. **安全性**: 遵循Supabase最佳实践，保护用户数据

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 发起Pull Request

## 许可证

MIT License

---

**开发者**: 基于原型HTML文件转换为Flutter应用
**更新时间**: 2024年12月 

## 2024-更新说明
- 统一替换logo图片为 assets/images/logo.png，已在App启动页、登录页、设置页及Web端相关页面生效，确保品牌形象一致。 
- 新增AI聊天页面（ai_chat_page.dart），支持AI与用户消息气泡、消息撤回、动画输入栏等，提升智能交互体验。
- 新增ChatBubble气泡组件，支持AI与用户不同样式，支持长按复制、消息撤回、AI头像自定义等功能。
- 故事广场（home_page.dart）新增丰富模拟数据，便于开发与演示。
- story_card组件修复了Row主轴无限宽度导致的布局异常，提升UI稳定性。
- 用户资料与故事内容支持在线更新，服务层（auth_service.dart、story_service.dart）增加update相关方法。
- 代码注释率提升，所有主要函数均含类型声明，符合项目注释与类型规范。
- **新增高保真原型子页面**：
  - `story_comment.html` - 故事评论页面，支持评论列表、发布评论、回复评论、长按菜单等功能
  - `story_share.html` - 故事分享页面，支持微信好友、朋友圈、复制链接等多种分享方式
  - `story_search.html` - 故事搜索页面，支持搜索建议、搜索历史、热门搜索、搜索结果等功能
  - `login_error.html` - 登录异常页面，支持验证码错误、账号不存在、协议提示等错误状态
  - `ai_character_manage.html` - AI角色管理页面，支持角色列表、添加编辑删除角色、表情头像选择等功能
  - `ai_chat_settings.html` - AI聊天设置页面，支持消息设置、语音设置、智能设置、数据管理等功能
  - `character_create.html` - 角色创建页面，支持分步骤创建、头像选择、性格标签、技能设置等功能
  - `story_create.html` - 故事创作页面，支持多标签页设计、章节管理、故事类型选择、发布设置等功能
- **原型文档对照完善**：根据 `modao_export_outline.md` 原型文档补充了缺失的子页面，确保高保真原型的完整性 

## 2024-06 功能更新

### 登录注册页面手机号校验优化
- 手机号输入框已严格按照原型校验格式，支持中国大陆手机号正则校验。
- 获取验证码按钮点击时会校验手机号格式，格式不正确时红色提示并阻止发送。
- 登录按钮点击时会校验手机号、验证码、协议勾选，未勾选协议时禁止登录并弹出红色提示。
- 所有校验失败均通过统一红色提示条展示，风格与原型一致。
- 相关校验逻辑已添加详细注释，所有函数参数均有类型声明。 

## 2024-06 登录页高保真还原更新

### 主要变更
- 登录页完全对齐高保真原型（login.html/index.html）：
  - 深色渐变背景+大量星星分布，支持多层次、不同透明度和大小，星空动画可扩展。
  - Logo固定旋转45°，外部多层呼吸光环动画，品牌色渐变扩散。
  - 主标题36px品牌色发光，副标题18px灰色，居中对齐，间距与原型一致。
  - 表单区紧凑居中，包含手机号输入、验证码输入+获取、协议勾选、主按钮、分割线、微信登录、底部帮助链接。
  - 输入框带icon、圆角、深色背景、品牌色边框，按钮风格极简，主按钮为渐变填充。
  - 协议勾选区横向紧凑，协议文本可点击。
  - 错误提示、分割线、微信登录、底部链接等细节全部还原。
  - 表单区整体滑入动画，键盘弹出时自动上移。
  - 手机号验证码登录流程为本地模拟，点击“获取验证码”直接倒计时，任意6位数字验证码即可通过。
- 代码结构模块化，星空背景、呼吸光环logo等为独立Widget，便于维护和复用。
- 主题色、圆角、渐变等全部引用app_theme.dart常量，禁止硬编码。
- 注释率≥30%，所有函数参数均有类型声明。
- 仅保留iOS/安卓平台内容，无web、macos、windows、linux相关内容。

### 体验说明
- 可在模拟器体验所有新功能，UI与原型一致，交互完整，视觉风格统一，代码结构清晰，注释充分。
- 兼容Flutter旧版本，MaterialStateProperty等API已做适配。 