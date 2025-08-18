# 通用组件库

这个目录包含了应用中可复用的通用组件，旨在提供统一的UI体验和减少代码重复。

## 组件列表

### 1. BaseCard - 通用卡片组件
提供统一的卡片样式和交互行为。

#### 基本用法
```dart
import '../widgets/common/index.dart';

BaseCard(
  onTap: () => print('点击卡片'),
  child: Text('卡片内容'),
)
```

#### 预设样式
```dart
// AI角色卡片
CardPresets.aiCharacterCard(
  child: CharacterContent(),
  onTap: () => navigateToDetail(),
);

// 会员卡片
CardPresets.membershipCard(
  membershipType: 'premium',
  child: MembershipContent(),
);

// 推荐内容卡片
CardPresets.recommendationCard(
  child: RecommendationContent(),
);
```

#### 特性
- 自动点击动画效果
- 涟漪效果支持
- 灵活的样式配置
- 会员等级自动配色
- 阴影和边框自定义

### 2. CustomTabBar - 自定义Tab栏
提供统一的Tab样式和交互。

#### 基本用法
```dart
CustomTabBar(
  tabs: ['推荐', '热门', '趋势'],
  currentIndex: _currentTab,
  onTap: (index) => setState(() => _currentTab = index),
)
```

#### 预设样式
```dart
// 主页Tab栏
TabBarPresets.homeTabBar(
  tabs: tabs,
  currentIndex: currentIndex,
  onTap: onTap,
);

// 市场页面Tab栏（无指示器）
TabBarPresets.marketplaceTabBar(
  tabs: tabs,
  currentIndex: currentIndex,
  onTap: onTap,
);

// 紧凑型Tab栏
TabBarPresets.compactTabBar(
  tabs: tabs,
  currentIndex: currentIndex,
  onTap: onTap,
);
```

#### 特性
- 可滚动的Tab列表
- 自定义指示器样式
- 灵活的字体和颜色配置
- 动画切换效果
- 响应式布局支持

### 3. CustomSearchBar - 搜索栏组件
提供统一的搜索体验。

#### 基本用法
```dart
CustomSearchBar(
  controller: _searchController,
  hintText: '搜索内容...',
  onChanged: (value) => _performSearch(value),
  onSubmitted: (value) => _submitSearch(value),
)
```

#### 预设样式
```dart
// 发现页面搜索栏
SearchBarPresets.discoverySearchBar(
  controller: controller,
  onChanged: onChanged,
  isSearchMode: isSearchMode,
);

// 智能体市场搜索栏
SearchBarPresets.marketplaceSearchBar(
  controller: controller,
  onChanged: onChanged,
  autofocus: true,
);

// 紧凑型搜索栏
SearchBarPresets.compactSearchBar(
  controller: controller,
  hintText: '快速搜索',
);
```

#### 特性
- 搜索模式自动切换
- 实时搜索支持
- 清除按钮自动显示
- 自定义图标和样式
- 键盘交互优化

## 设计原则

### 1. 一致性
- 所有组件遵循统一的设计规范
- 使用Sprint3设计令牌系统
- 保持视觉和交互的一致性

### 2. 可复用性
- 组件高度可配置
- 提供多种预设样式
- 支持自定义扩展

### 3. 性能优化
- 动画使用SingleTickerProviderStateMixin
- 合理的组件生命周期管理
- 内存泄漏预防

### 4. 无障碍支持
- 合适的点击区域大小
- 语义化的组件结构
- 键盘导航支持

## 使用建议

1. **优先使用预设样式**: 减少重复代码，保持一致性
2. **合理配置动画**: 避免过度动画影响性能
3. **响应式设计**: 考虑不同屏幕尺寸的适配
4. **测试交互**: 确保在不同设备上的交互体验

## 扩展指南

如需添加新的通用组件:

1. 在此目录下创建组件文件
2. 遵循现有的命名和结构规范
3. 提供预设样式选项
4. 在`index.dart`中导出
5. 更新此README文档

## 版本更新

- v1.0.0: 初始版本，包含BaseCard、CustomTabBar、CustomSearchBar