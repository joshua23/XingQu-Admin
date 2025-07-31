# 星趣App重构设计规范文档 (DESIGN_SPEC.md)

## 1. 设计目标与原则

### 1.1 设计目标
- 严格按照《星趣品牌视觉识别系统设计规范》执行
- 实现原型文件的高保真Flutter还原
- 保持品牌一致性和用户体验连贯性

### 1.2 设计原则
- **趣味活力**: 暗色赛博氛围 + 极简几何
- **几何抽象**: 动态留白 + 可变系统
- **视觉语法**: 大面积黑色承托，浅米色与高饱和亮色点缀
- **品牌符号**: 星形与笑脸作为人格化符号

## 2. 颜色系统规范

### 2.1 主色调定义
```dart
// 主色 (使用比例70%)
static const Color background = Color(0xFF000000);     // 极夜黑
static const Color primary = Color(0xFFF5DFAF);        // 浅米色 (15%)

// 强调色 (使用比例10%)  
static const Color accent = Color(0xFFFFC542);         // 琥珀黄
static const Color highlight = Color(0xFFAAB2C8);      // 浅灰蓝 (5%)

// 功能色
static const Color success = Color(0xFFB7C68B);        // 浅橄榄绿
static const Color warning = Color(0xFFFFC542);        // 警告黄
static const Color error = Color(0xFFFF5757);          // 错误红

// 中性色
static const Color textPrimary = Color(0xFFFFFFFF);    // 文字高亮
static const Color textSecondary = Color(0xFFCFCFCF);  // 文本普通
static const Color cardBackground = Color(0xFF1E1E1E); // 卡片底色
```

### 2.2 配色使用原则
- **深色优先**: 70%使用极夜黑作为主背景
- **品牌色点缀**: 15%使用浅米色作为品牌识别
- **强调色提升**: 10%琥珀黄用于点赞、通知等重要操作
- **辅助色补充**: 5%浅灰蓝用于按钮高亮、链接

## 3. 字体系统规范

### 3.1 字体层级
```dart
// 标题字体 (HarmonyOS Sans SC Bold)
static const TextStyle h1 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textPrimary,
  height: 1.4,
  letterSpacing: 0.02,
);

static const TextStyle h2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold, 
  color: textPrimary,
  height: 1.4,
  letterSpacing: 0.02,
);

// 正文字体 (思源黑体 Regular)
static const TextStyle body1 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: textSecondary,
  height: 1.4,
  letterSpacing: 0.02,
);

static const TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textSecondary,
  height: 1.4,
  letterSpacing: 0.02,
);
```

### 3.2 排版规范
- **行距**: 1.4倍字号
- **字间距**: +2%提升呼吸感
- **对齐**: 标题居左，正文左对齐

## 4. 组件设计规范

### 4.1 标志规范
- **位置**: 页面左上角45度位置
- **尺寸**: 页面比例的1/4
- **元素**: 两个星星 + 一个笑脸/嘴巴 + 右侧星星上方眉毛
- **颜色**: 浅米色(#F5DFAF)元素，黑色背景
- **安全空间**: 四周最小留白 ≥ 0.5X

### 4.2 卡片组件
```dart
Container(
  decoration: BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12), // 12dp圆角
    border: Border.all(color: Colors.grey.withOpacity(0.1)),
  ),
  // ...
)
```

### 4.3 按钮组件
```dart
// 主要按钮 (琥珀黄)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  // ...
)

// 次要按钮 (浅灰蓝)
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: highlight,
    side: BorderSide(color: highlight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  // ...
)
```

### 4.4 图标规范
- **描边**: 2px圆角描边
- **激活状态**: 填充强调色(琥珀黄)
- **品牌一致性**: 保持与星形、笑脸元素的视觉一致

## 5. 页面布局规范

### 5.1 主界面结构
- **底部导航**: 5个Tab页（首页、消息、创作、发现、我的）
- **悬浮按钮**: 琥珀黄"+"按钮
- **卡片布局**: 瀑布流2列排布
- **间距**: 统一使用8dp网格系统

### 5.2 功能页面规范
#### 发现页
- **搜索栏**: 圆角20dp
- **筛选标签**: 星形标签做兴趣筛选
- **内容区**: 钻石榜、星野市集、分类导航

#### 聊天页
- **气泡**: 暗灰/琥珀黄配色
- **发送按钮**: 笑脸弧线变形
- **输入框**: 圆角设计，深色背景

#### 个人页
- **头像**: 可选择星形蒙版
- **统计数据**: 星形雷达图展示
- **背景**: 渐变深色背景

## 6. 动效系统规范

### 6.1 基础动效
```dart
// 加载动效：星形自中心放大至1.2倍后回弹
AnimatedScale(
  scale: isLoading ? 1.2 : 1.0,
  duration: Duration(milliseconds: 600),
  curve: Curves.elasticOut,
  child: StarIcon(),
)

// 点击反馈：星形爆破为6颗迷你星
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOut,
  // 爆破动画实现
)
```

### 6.2 页面转场
- **滑入动画**: 新页面从右侧滑入
- **淡入淡出**: Modal弹窗使用淡入淡出
- **弹性动画**: 按钮点击使用弹性回弹

## 7. 状态设计规范

### 7.1 空状态页面
- **插画**: 米色线稿插画
- **动画**: 星星跳动增强趣味性
- **文案**: 简洁友好的提示文字

### 7.2 加载状态
- **加载器**: 旋转的星形组合
- **进度条**: 笑脸弧线变形
- **骨架屏**: 深色背景下的浅色占位

### 7.3 错误状态
- **颜色**: 错误红(#FF5757)
- **图标**: 破碎的星形
- **操作**: 重试按钮采用琥珀黄

## 8. 响应式设计规范

### 8.1 屏幕适配
- **基准尺寸**: iPhone 15 Pro (393×852)
- **缩放策略**: 等比缩放，保持16:9比例
- **断点**: 小屏(<375px)、中屏(375-414px)、大屏(>414px)

### 8.2 组件适配
- **文字**: 根据屏幕密度自动缩放
- **图标**: 矢量图标，支持多尺寸
- **间距**: 使用相对单位(dp)，保持比例

## 9. 可访问性规范

### 9.1 对比度要求
- **文字对比**: 符合WCAG 2.1 AA标准
- **色彩识别**: 不仅依赖颜色传达信息
- **触控目标**: 最小44dp触控区域

### 9.2 动效友好
- **减弱动画**: 尊重系统动画偏好设置
- **语义化**: 提供语音朗读支持
- **焦点管理**: 键盘导航友好

---

**设计师确认**: 设计规范制定完成，请前端工程师开始技术实现。

请输入 **/前端开发** 继续下一步，或 **/策略修改** 对设计策略进行调整。