# 星趣app 设计文档

---

## UI风格指南 / HIG（以《星趣app-UI风格指南.md》为准）

> 本节内容完全参照《星趣app-UI风格指南.md》，如有更新请以该文档为唯一标准。

# 星趣品牌视觉识别系统设计规范

---

## 总体基调
- 关键词：趣味、活力、暗色赛博氛围、极简几何
- 设计技法：几何抽象＋动态留白＋可变系统
- 视觉语法：大面积黑色承托，点缀浅米色与高饱和亮色；星形与笑脸作为品牌人格化符号，强调年轻、轻松、可互动

---

## 1. 标志规范
### 1.1 基本元素
- 标志由两个星星、一个笑脸/嘴巴以及右侧星星上方的眉毛组成，不增加也不减少元素
- 标志应放置在页面左上角45度位置，尺寸为页面比例的1/4

### 1.2 标志版本
- 主标志：浅米色（#F5DFAF）元素，置于纯黑（#000000）背景
- 反白版：黑色元素置于浅米色底，用于浅色界面
- 单色版：白色（#FFFFFF）或灰色（#8A8A8A），用于低对比度场景

### 1.3 安全空间
- 以星形最大外接圆直径 = X
- 四周最小留白 ≥ 0.5X

### 1.4 最小尺寸
- 数字端 ≥ 24px 高
- 印刷 ≥ 5mm 高

### 1.5 禁用示例
- 不可拉伸或旋转
- 不可添加描边或阴影
- 不可改变颜色
- 不可与背景图产生低对比
- 不可更改元素位置关系

---

## 2. 颜色系统
### 2.1 主色
- 浅米色 #F5DFAF（使用比例15%）——品牌识别色
- 极夜黑 #000000（使用比例70%）——主背景色

### 2.2 强调色
- 琥珀黄 #FFC542（使用比例10%）——点赞、通知、重要操作
- 浅灰蓝 #AAB2C8（使用比例5%）——按钮高亮、链接

### 2.3 功能色
- 浅橄榄绿 #B7C68B ——成功
- 警告 #FFC542
- 错误 #FF5757

### 2.4 中性色
- 文字高亮 #FFFFFF
- 文本普通 #CFCFCF
- 卡片底色 #1E1E1E

### 2.5 配色原则
- 深色优先，亮色作点缀，确保暗黑模式友好
- 浅色模式将黑色/深灰反转为 #FFFFFF/#F5F5F5
- 确保文字与背景对比度符合无障碍标准

---

## 3. 字体系统
### 3.1 中文字体
- 主标题：HarmonyOS Sans SC Bold
- 副标题/正文：思源黑体(Noto Sans SC) Regular

### 3.2 英文及数字字体
- Inter 或 Roboto

### 3.3 字号层级（sp单位）
- H1 标题：24sp
- H2 标题：20sp
- 正文：16sp
- 说明文字：12sp

### 3.4 排版规范
- 行距：1.4倍字号
- 字间距：+2%提升呼吸感
- 对齐：标题居左，正文左对齐

---

## 4. 图形元素与模式
### 4.1 基础图形
- 星形变体：四角圆角化、45°旋转，生成3级大小，可用作动效粒子
- 弧线笑脸：提取弧度做分隔线或进度条

### 4.2 组合模式
- 星形与弧线进行30°旋转和镜像，形成重复图案
- 用于启动页、空状态背景等

### 4.3 动态系统
- 加载动效：星形自中心放大至1.2倍后回弹
- 点击反馈：星形爆破为6颗迷你星

### 4.4 图标规范
- 2px圆角描边
- 激活状态填充强调色
- 保持与品牌元素的视觉一致性

---

## 5. APP应用场景

> 本章节详细列举各主要页面的UI控件参数，所有参数均来源于"星野app截图识别出的文档"下的图标解析文档。每个页面均包含：页面描述、UI控件参数表（含类型、坐标、交互、功能说明）、主要交互说明。参数表采用JSON+注释形式，便于开发查阅。

### 5.1 首页-精选页（对应：首页-精选页-图标解析.md）
- 页面描述：
  - 首页-精选页是用户进入应用后的默认首页，聚焦于AI角色的个性化推荐与互动，是星趣app的核心内容入口。
  - 布局结构包括：
    1. 顶部状态栏（时间显示、WiFi状态、通知数、FM频道入口、搜索入口、小红书分享等）
    2. 角色信息区（头像、昵称、连接者数量、消息数、关注按钮等）
    3. 主体内容区（AI生成动漫图片、角色简介、特征标签、对话交互区）
    4. 交互控制区（消息输入、语音/文本切换、格式化按钮、功能扩展、快捷回复等）
    5. 底部Tab栏（五大主功能模块切换及小红书分享入口）
  - 主要交互：支持语音/文本输入、快捷关注、评论区弹窗、内容分享、日历、FM频道跳转、Tab切换等。所有跳转和弹窗均有标准化流程。
  - 典型业务流程：选择角色→开始对话→关注角色（未登录弹登录注册）→查看详情/评论→内容分享→FM频道跳转。
  - 主要组件：状态栏、角色卡片、AI图片、对话气泡、输入框、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "text", "bbox": [0.5, 0.110, 0.578, 0.126], "interactivity": false, "content": "3695"}, // 消息数量提示
  {"type": "text", "bbox": [0.143, 0.129, 0.330, 0.147], "interactivity": false, "content": "92.4"}, // 粉丝/连接人数
  {"type": "icon", "bbox": [0.028, 0.704, 0.159, 0.737], "interactivity": true, "content": "3 "}, // 底部Tab消息icon
  {"type": "icon", "bbox": [0.179, 0.059, 0.255, 0.087], "interactivity": true, "content": "FM "}, // FM频道入口
  {"type": "icon", "bbox": [0.040, 0.013, 0.157, 0.038], "interactivity": true, "content": "14:16 "}, // 顶部时间栏
  {"type": "icon", "bbox": [0.445, 0.934, 0.554, 0.973], "interactivity": true, "content": "Strikethrough"}, // 格式化按钮
  {"type": "icon", "bbox": [0.453, 0.106, 0.543, 0.150], "interactivity": true, "content": "Chat message"}, // 对话气泡入口
  {"type": "icon", "bbox": [0.441, 0.052, 0.572, 0.098], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书分享
  {"type": "icon", "bbox": [0.885, 0.053, 0.974, 0.103], "interactivity": true, "content": "Find"}, // 搜索/发现
  {"type": "icon", "bbox": [0.037, 0.059, 0.131, 0.086], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书分享
  {"type": "icon", "bbox": [0.294, 0.053, 0.416, 0.096], "interactivity": true, "content": "Xiaohongshu"}, // 小红书分享
  {"type": "icon", "bbox": [0.890, 0.104, 0.975, 0.157], "interactivity": true, "content": "Increase"}, // 增加/关注
  {"type": "icon", "bbox": [0.767, 0.863, 0.837, 0.910], "interactivity": true, "content": "Reload"}, // 刷新
  {"type": "icon", "bbox": [0.853, 0.862, 0.966, 0.913], "interactivity": true, "content": "Add"}, // 加号按钮
  {"type": "icon", "bbox": [0.027, 0.857, 0.142, 0.913], "interactivity": true, "content": "Calendar"}, // 日历入口
  {"type": "icon", "bbox": [0.0, 0.922, 0.211, 0.992], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.878, 0.015, 0.947, 0.038], "interactivity": true, "content": "48"}, // 右上角通知数
  {"type": "icon", "bbox": [0.709, 0.014, 0.816, 0.040], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi状态
  {"type": "icon", "bbox": [0.348, 0.113, 0.413, 0.144], "interactivity": true, "content": "Add"}, // 卡片关注
  {"type": "icon", "bbox": [0.652, 0.936, 0.750, 0.965], "interactivity": true, "content": "Xiaohongshu"} // Tab小红书
]
```

### 5.2 首页-综合-推荐页（对应：首页-综合-推荐页-图标解析.md）
- 页面描述：
  - 推荐页是综合页的默认首页，采用智能算法为用户推荐最受欢迎和最适合的AI角色。页面以网格布局展示精选角色，每个角色卡片包含丰富的视觉信息和基本属性，帮助用户快速找到感兴趣的AI伙伴。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频状态、通知数）
    2. 功能入口区（FM频道、搜索、Highlight高亮、角色设计、Xray分析、小红书分享等）
    3. 顶部导航（综合页Tab标签栏，推荐Tab高亮）
    4. 主体内容区（2列2行网格布局，4个角色卡片，统一设计风格）
    5. 底部统计区（推荐统计数据）
    6. 底部Tab栏（小红书分享入口等）
  - 主要交互：支持角色卡片点击查看详情、关注、评论、内容分享、Tab切换、FM频道跳转、Highlight高亮、Xray分析等。
  - 典型业务流程：进入推荐页→浏览推荐角色→选择感兴趣角色→查看详情/互动/关注/分享→FM频道跳转。
  - 主要组件：状态栏、角色卡片、统计区、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "text", "bbox": [0.824, 0.903, 0.967, 0.921], "interactivity": false, "content": "31.3"}, // 推荐页底部统计
  {"type": "icon", "bbox": [0.877, 0.015, 0.951, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.174, 0.057, 0.272, 0.088], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.505, 0.382, 0.988, 0.539], "interactivity": true, "content": "1.1 "}, // 推荐角分数
  {"type": "icon", "bbox": [0.013, 0.396, 0.496, 0.540], "interactivity": true, "content": "92.4 "}, // 推荐连接数
  {"type": "icon", "bbox": [0.040, 0.014, 0.156, 0.039], "interactivity": true, "content": "14:16 "}, // 顶部时间
  {"type": "icon", "bbox": [0.012, 0.790, 0.497, 0.906], "interactivity": true, "content": "@Kfh1LUVo 13.1 "}, // 推荐角昵称分数
  {"type": "icon", "bbox": [0.331, 0.101, 0.548, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.447, 0.934, 0.553, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.710, 0.015, 0.763, 0.038], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.766, 0.015, 0.815, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.453, 0.058, 0.561, 0.088], "interactivity": true, "content": "Xiaohongshu"}, // 小红书
  {"type": "icon", "bbox": [0.558, 0.101, 0.745, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.160, 0.101, 0.313, 0.147], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.023, 0.057, 0.152, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.892, 0.059, 0.965, 0.095], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.301, 0.056, 0.411, 0.090], "interactivity": true, "content": "Character Designer"}, // 角色设计
  {"type": "icon", "bbox": [0.758, 0.101, 0.907, 0.150], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.936, 0.101, 1.0, 0.149], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.014, 0.105, 0.141, 0.141], "interactivity": true, "content": "Show/HideHide&HideHide"}, // 显隐
  {"type": "icon", "bbox": [0.654, 0.938, 0.749, 0.964], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.211, 0.930, 0.387, 0.974], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.053, 0.936, 0.148, 0.967], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.853, 0.936, 0.944, 0.966], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.523, 0.899, 0.691, 0.921], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"} // Tab小红书
]
```

### 5.3 首页-综合-订阅页（对应：首页-综合-订阅页-图标解析.md）
- 页面描述：
  - 订阅页聚焦于用户已订阅频道的内容聚合与管理，便于用户快速访问和管理关注的AI频道及其动态。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音量、通知数）
    2. 频道入口区（FM频道、角色设计、Highlight高亮、小红书分享等）
    3. 主体内容区（订阅频道列表、频道卡片、快捷入口、下拉选择等）
    4. 底部Tab栏（主功能切换、小红书分享入口）
  - 主要交互：支持频道卡片点击、FM频道跳转、下拉选择、内容高亮、Tab切换、分享、搜索、顶部时间、角色设计等。
  - 典型业务流程：进入订阅页→浏览订阅频道→点击频道卡片→查看详情/互动/分享→FM频道跳转。
  - 主要组件：状态栏、频道卡片、下拉选择、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "icon", "bbox": [0.877, 0.015, 0.949, 0.037], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.183, 0.058, 0.257, 0.088], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.040, 0.014, 0.153, 0.038], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.448, 0.934, 0.552, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.459, 0.058, 0.556, 0.087], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.768, 0.016, 0.815, 0.036], "interactivity": true, "content": "A volume control or volume indicator."}, // 音量
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.036], "interactivity": true, "content": "A volume control or volume indicator."}, // 音量
  {"type": "icon", "bbox": [0.711, 0.015, 0.762, 0.037], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.324, 0.101, 0.554, 0.148], "interactivity": true, "content": "Xiaohongshu (⌘N)"}, // 小红书快捷入口
  {"type": "icon", "bbox": [0.554, 0.101, 0.754, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.751, 0.102, 0.915, 0.149], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.157, 0.101, 0.321, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.309, 0.058, 0.407, 0.090], "interactivity": true, "content": "Character Design"}, // 角色设计
  {"type": "icon", "bbox": [0.897, 0.062, 0.961, 0.092], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.0, 0.101, 0.161, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.024, 0.057, 0.153, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.254, 0.936, 0.346, 0.966], "interactivity": true, "content": "Combo Box"}, // 下拉选择
  {"type": "icon", "bbox": [0.934, 0.101, 1.0, 0.148], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.056, 0.937, 0.146, 0.967], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.638, 0.933, 0.769, 0.972], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.855, 0.936, 0.943, 0.966], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"} // Tab小红书
]
```

### 5.4 首页-综合-智能体页（对应：首页-综合-智能体页-图标解析.md）
- 页面描述：
  - 智能体页聚焦于AI智能体的聚合、分组与管理，便于用户查看、管理和互动各类AI智能体。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频、通知数）
    2. 智能体分组区（分组统计、分组卡片、图片/相册、主页设计等）
    3. 主体内容区（智能体列表、分组统计、快捷入口等）
    4. 底部Tab栏（主功能切换、小红书分享入口）
  - 主要交互：支持分组统计、智能体卡片点击、主页设计、图片浏览、Tab切换、分享、搜索、FM入口、音频等。
  - 典型业务流程：进入智能体页→浏览分组→点击智能体卡片→查看详情/互动/分享→主页设计。
  - 主要组件：状态栏、分组卡片、图片、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "icon", "bbox": [0.506, 0.416, 0.989, 0.539], "interactivity": true, "content": "@ 43.5"}, // 智能体分组/统计
  {"type": "icon", "bbox": [0.877, 0.015, 0.951, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.170, 0.057, 0.270, 0.087], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.012, 0.406, 0.497, 0.540], "interactivity": true, "content": "@ 17.0"}, // 分组/统计
  {"type": "icon", "bbox": [0.042, 0.014, 0.153, 0.038], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.008, 0.541, 0.988, 0.907], "interactivity": true, "content": "@ 17.9"}, // 分组/统计
  {"type": "icon", "bbox": [0.447, 0.934, 0.553, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.326, 0.101, 0.549, 0.151], "interactivity": true, "content": "Kodak"}, // 图片/相册
  {"type": "icon", "bbox": [0.559, 0.101, 0.747, 0.151], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.766, 0.015, 0.815, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.710, 0.015, 0.763, 0.038], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.455, 0.058, 0.559, 0.087], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.159, 0.101, 0.318, 0.152], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.001, 0.101, 0.152, 0.151], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.023, 0.057, 0.151, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.763, 0.101, 0.906, 0.148], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.896, 0.061, 0.962, 0.092], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.308, 0.058, 0.408, 0.089], "interactivity": true, "content": "Home Design"}, // 主页设计
  {"type": "icon", "bbox": [0.937, 0.101, 1.0, 0.148], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.010, 0.921, 0.200, 0.996], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.210, 0.928, 0.384, 0.976], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.633, 0.932, 0.777, 0.974], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.804, 0.929, 0.989, 0.977], "interactivity": true, "content": "Kohongshu (Kohoo)"} // 小红书变体
]
```

### 5.5 首页-综合-记忆簿页（对应：首页-综合-记忆簿页-图标解析.md）
- 页面描述：
  - 记忆簿页聚焦于用户的记忆内容聚合与管理，支持多分组、多主题的记忆条目浏览与操作。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频、通知数）
    2. 记忆分组区（分组统计、分组卡片、系统相关、AI、国际化、帮助等）
    3. 主体内容区（记忆条目列表、分组、标签、快捷入口等）
    4. 底部Tab栏（主功能切换、小红书分享入口）
  - 主要交互：支持分组统计、记忆条目浏览、系统相关操作、AI相关、国际化、帮助、切换、导航、主题切换、FM入口、Tab栏、幼儿/动物/狮子主题、AI、国际化、帮助、切换、导航、分享、搜索等。
  - 典型业务流程：进入记忆簿页→浏览分组/条目→操作/切换主题→查看详情/互动/分享。
  - 主要组件：状态栏、分组卡片、记忆条目、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "text", "bbox": [0.033, 0.393, 0.172, 0.411], "interactivity": false, "content": "@"}, // 用户标识/分组
  {"type": "text", "bbox": [0.357, 0.394, 0.480, 0.412], "interactivity": false, "content": "7068"}, // 记忆条目数
  {"type": "text", "bbox": [0.846, 0.394, 0.967, 0.412], "interactivity": false, "content": "6911"}, // 记忆条目数
  {"type": "text", "bbox": [0.038, 0.665, 0.302, 0.683], "interactivity": false, "content": "@/8iD9hty0"}, // 用户唯一标识
  {"type": "text", "bbox": [0.357, 0.667, 0.478, 0.685], "interactivity": false, "content": "6707"}, // 记忆条目数
  {"type": "text", "bbox": [0.846, 0.667, 0.971, 0.685], "interactivity": false, "content": "5975"}, // 记忆条目数
  {"type": "icon", "bbox": [0.167, 0.056, 0.275, 0.089], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.877, 0.014, 0.949, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.037, 0.013, 0.156, 0.039], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.296, 0.053, 0.419, 0.098], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.016, 0.055, 0.152, 0.089], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.444, 0.056, 0.569, 0.091], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.494, 0.101, 0.667, 0.150], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.706, 0.014, 0.764, 0.038], "interactivity": true, "content": "WiFi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.257, 0.101, 0.478, 0.149], "interactivity": true, "content": "Kindergarten"}, // 标签/分组
  {"type": "icon", "bbox": [0.890, 0.056, 0.966, 0.098], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.765, 0.015, 0.816, 0.038], "interactivity": true, "content": "SoundCloud"}, // 音乐/音频
  {"type": "icon", "bbox": [0.106, 0.205, 0.474, 0.238], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.823, 0.015, 0.873, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.687, 0.101, 0.827, 0.152], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.445, 0.934, 0.558, 0.973], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.039, 0.163, 0.103, 0.195], "interactivity": true, "content": "Groups"}, // 分组
  {"type": "icon", "bbox": [0.531, 0.164, 0.591, 0.196], "interactivity": true, "content": "Dictation"}, // 听写
  {"type": "icon", "bbox": [0.855, 0.101, 0.976, 0.150], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.0, 0.101, 0.062, 0.147], "interactivity": true, "content": "New"}, // 新建
  {"type": "icon", "bbox": [0.593, 0.204, 0.957, 0.238], "interactivity": true, "content": "a digital assistant."}, // 数字助理
  {"type": "icon", "bbox": [0.107, 0.791, 0.474, 0.825], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.039, 0.245, 0.102, 0.277], "interactivity": true, "content": "Animal Jam"}, // 动物主题
  {"type": "icon", "bbox": [0.106, 0.245, 0.413, 0.278], "interactivity": true, "content": "Video Editor"}, // 视频编辑
  {"type": "icon", "bbox": [0.037, 0.518, 0.104, 0.551], "interactivity": true, "content": "Dictation"}, // 听写
  {"type": "icon", "bbox": [0.527, 0.244, 0.592, 0.278], "interactivity": true, "content": "Dictation"}, // 听写
  {"type": "icon", "bbox": [0.038, 0.204, 0.103, 0.236], "interactivity": true, "content": "Dictation"}, // 听写
  {"type": "icon", "bbox": [0.096, 0.101, 0.229, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.595, 0.751, 0.958, 0.785], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.595, 0.791, 0.958, 0.825], "interactivity": true, "content": "T-Mobile"}, // 运营商/网络
  {"type": "icon", "bbox": [0.594, 0.832, 0.957, 0.865], "interactivity": true, "content": "A digital assistant."}, // 数字助理
  {"type": "icon", "bbox": [0.105, 0.164, 0.476, 0.197], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.591, 0.711, 0.957, 0.744], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.033, 0.791, 0.104, 0.823], "interactivity": true, "content": "Globe"}, // 地球/国际化
  {"type": "icon", "bbox": [0.526, 0.205, 0.591, 0.238], "interactivity": true, "content": "Kindergarten Kids Learning"}, // 幼儿学习
  {"type": "icon", "bbox": [0.596, 0.245, 0.926, 0.278], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.106, 0.477, 0.346, 0.511], "interactivity": true, "content": "Xiaohongshu (X)"}, // 小红书
  {"type": "icon", "bbox": [0.528, 0.517, 0.594, 0.551], "interactivity": true, "content": "Globe Globe"}, // 地球/国际化
  {"type": "icon", "bbox": [0.105, 0.711, 0.474, 0.743], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.221, 0.930, 0.383, 0.972], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.035, 0.748, 0.105, 0.783], "interactivity": true, "content": "Lion"}, // 狮子主题
  {"type": "icon", "bbox": [0.039, 0.434, 0.103, 0.470], "interactivity": true, "content": "Navigator"}, // 导航
  {"type": "icon", "bbox": [0.595, 0.518, 0.690, 0.551], "interactivity": true, "content": "Al"}, // AI相关
  {"type": "icon", "bbox": [0.106, 0.832, 0.291, 0.865], "interactivity": true, "content": "Kindergarten"}, // 幼儿分组
  {"type": "icon", "bbox": [0.107, 0.519, 0.232, 0.551], "interactivity": true, "content": "Help & Support"}, // 帮助与支持
  {"type": "icon", "bbox": [0.641, 0.930, 0.772, 0.975], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.041, 0.475, 0.103, 0.509], "interactivity": true, "content": "Toggleoggleoggle Box"}, // 切换/开关
  {"type": "icon", "bbox": [0.033, 0.830, 0.105, 0.865], "interactivity": true, "content": "Lion"}, // 狮子主题
  {"type": "icon", "bbox": [0.033, 0.934, 0.164, 0.970], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.856, 0.875, 0.960, 0.914], "interactivity": true, "content": "Show all actions"}, // 展开全部操作
  {"type": "icon", "bbox": [0.522, 0.788, 0.594, 0.824], "interactivity": true, "content": "Globe Globe"}, // 地球/国际化
  {"type": "icon", "bbox": [0.031, 0.707, 0.104, 0.743], "interactivity": true, "content": "Earth Globe"}, // 地球/国际化
  {"type": "icon", "bbox": [0.106, 0.286, 0.404, 0.318], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.034, 0.284, 0.104, 0.320], "interactivity": true, "content": "Dictation"} // 听写
]
```

### 5.6 首页-综合-双语页（对应：首页-综合-双语页-图标解析.md）
- 页面描述：
  - 双语页聚焦于中英双语内容的聚合与展示，便于用户切换和学习多语言内容。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频、通知数）
    2. 统计区（左/右统计、分组、标签等）
    3. 主体内容区（双语内容列表、文本输入、格式化、系统相关等）
    4. 底部Tab栏（主功能切换、小红书分享入口）
  - 主要交互：支持统计查看、双语内容切换、文本输入、格式化、系统相关、Tab切换、分享、搜索、角色设计、文本格式化、新建等。
  - 典型业务流程：进入双语页→浏览内容→切换语言→输入/格式化文本→互动/分享。
  - 主要组件：状态栏、统计区、内容列表、文本输入、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "text", "bbox": [0.033, 0.906, 0.203, 0.924], "interactivity": false, "content": "@"}, // 用户标识/分组
  {"type": "text", "bbox": [0.375, 0.908, 0.478, 0.924], "interactivity": false, "content": "515"}, // 统计数
  {"type": "icon", "bbox": [0.877, 0.015, 0.951, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.170, 0.057, 0.272, 0.087], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.504, 0.407, 0.989, 0.541], "interactivity": true, "content": "758 "}, // 右侧统计
  {"type": "icon", "bbox": [0.009, 0.380, 0.496, 0.545], "interactivity": true, "content": "764 "}, // 左侧统计
  {"type": "icon", "bbox": [0.043, 0.014, 0.152, 0.038], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.447, 0.934, 0.553, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.766, 0.015, 0.815, 0.037], "interactivity": true, "content": "A volume control or volume indicator."}, // 音量
  {"type": "icon", "bbox": [0.710, 0.015, 0.763, 0.038], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.483, 0.101, 0.670, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.256, 0.101, 0.470, 0.148], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.456, 0.058, 0.559, 0.088], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.681, 0.101, 0.832, 0.148], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.020, 0.057, 0.152, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.086, 0.101, 0.236, 0.147], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.0, 0.101, 0.066, 0.148], "interactivity": true, "content": "New"}, // 新建
  {"type": "icon", "bbox": [0.843, 0.102, 0.990, 0.146], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.896, 0.061, 0.962, 0.092], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.309, 0.059, 0.407, 0.089], "interactivity": true, "content": "Character Design"}, // 角色设计
  {"type": "icon", "bbox": [0.431, 0.160, 0.479, 0.180], "interactivity": true, "content": "Text formatting options."}, // 文本格式化
  {"type": "icon", "bbox": [0.054, 0.937, 0.147, 0.966], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.201, 0.932, 0.394, 0.972], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.522, 0.158, 0.604, 0.181], "interactivity": true, "content": "System"}, // 系统相关
  {"type": "icon", "bbox": [0.657, 0.937, 0.746, 0.964], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.919, 0.160, 0.964, 0.182], "interactivity": true, "content": "Text Box"}, // 文本输入框
  {"type": "icon", "bbox": [0.853, 0.936, 0.944, 0.966], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.034, 0.159, 0.116, 0.180], "interactivity": true, "content": "Xiaohongshu (Xia)"} // 小红书
]
```

### 5.7 首页-综合-挑战页（对应：首页-综合-挑战页-图标解析.md）
- 页面描述：
  - 挑战页聚焦于各类AI挑战内容的聚合与互动，便于用户参与、查看和管理挑战任务。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频、通知数）
    2. 挑战统计区（挑战数、分组统计、图片/头像等）
    3. 主体内容区（挑战任务列表、分组、标签、快捷入口等）
    4. 底部Tab栏（主功能切换、小红书分享入口）
  - 主要交互：支持挑战统计、任务浏览、分组切换、图片浏览、Tab切换、分享、搜索、FM入口、图片、分组切换、新建等。
  - 典型业务流程：进入挑战页→浏览挑战任务→参与/切换分组→查看详情/互动/分享。
  - 主要组件：状态栏、统计区、任务列表、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "icon", "bbox": [0.171, 0.056, 0.274, 0.088], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.877, 0.015, 0.951, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.012, 0.418, 0.496, 0.541], "interactivity": true, "content": "189 "}, // 挑战数/统计
  {"type": "icon", "bbox": [0.504, 0.622, 0.988, 0.824], "interactivity": true, "content": "@ 272 "}, // 用户/分组统计
  {"type": "icon", "bbox": [0.504, 0.272, 0.987, 0.486], "interactivity": true, "content": "@ 173 "}, // 用户/分组统计
  {"type": "icon", "bbox": [0.041, 0.014, 0.153, 0.038], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.011, 0.796, 0.495, 0.908], "interactivity": true, "content": "99 "}, // 挑战完成数/统计
  {"type": "icon", "bbox": [0.502, 0.825, 0.988, 0.922], "interactivity": true, "content": "A painting or painting of a person."}, // 挑战相关图片/头像
  {"type": "icon", "bbox": [0.447, 0.934, 0.553, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.484, 0.101, 0.667, 0.150], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.261, 0.101, 0.467, 0.147], "interactivity": true, "content": "V-Line"}, // 分割线/标记
  {"type": "icon", "bbox": [0.766, 0.015, 0.815, 0.037], "interactivity": true, "content": "Sound"}, // 音量
  {"type": "icon", "bbox": [0.709, 0.014, 0.763, 0.038], "interactivity": true, "content": "WiFi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.823, 0.015, 0.872, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.686, 0.101, 0.827, 0.149], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.453, 0.058, 0.561, 0.088], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.020, 0.056, 0.152, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.091, 0.101, 0.231, 0.147], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.846, 0.102, 0.991, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.302, 0.053, 0.412, 0.097], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.892, 0.058, 0.965, 0.095], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.0, 0.103, 0.061, 0.141], "interactivity": true, "content": "New"}, // 新建
  {"type": "icon", "bbox": [0.009, 0.920, 0.200, 0.996], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.204, 0.927, 0.393, 0.976], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.802, 0.927, 0.993, 0.979], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.612, 0.929, 0.792, 0.975], "interactivity": true, "content": "Xray"} // 透视
]
```

### 5.8 首页-综合-推荐页（对应：首页-综合-推荐页-图标解析.md）
- 页面描述：
  - 推荐页是综合页的默认首页，采用智能算法为用户推荐最受欢迎和最适合的AI角色。页面以网格布局展示精选角色，每个角色卡片包含丰富的视觉信息和基本属性，帮助用户快速找到感兴趣的AI伙伴。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、音频状态、通知数）
    2. 功能入口区（FM频道、搜索、Highlight高亮、角色设计、Xray分析、小红书分享等）
    3. 顶部导航（综合页Tab标签栏，推荐Tab高亮）
    4. 主体内容区（2列2行网格布局，4个角色卡片，统一设计风格）
    5. 底部统计区（推荐统计数据）
    6. 底部Tab栏（小红书分享入口等）
  - 主要交互：支持角色卡片点击查看详情、关注、评论、内容分享、Tab切换、FM频道跳转、Highlight高亮、Xray分析等。
  - 典型业务流程：进入推荐页→浏览推荐角色→选择感兴趣角色→查看详情/互动/关注/分享→FM频道跳转。
  - 主要组件：状态栏、角色卡片、统计区、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "text", "bbox": [0.824, 0.903, 0.967, 0.921], "interactivity": false, "content": "31.3"}, // 推荐页底部统计
  {"type": "icon", "bbox": [0.877, 0.015, 0.951, 0.038], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.174, 0.057, 0.272, 0.088], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.505, 0.382, 0.988, 0.539], "interactivity": true, "content": "1.1 "}, // 推荐角分数
  {"type": "icon", "bbox": [0.013, 0.396, 0.496, 0.540], "interactivity": true, "content": "92.4 "}, // 推荐连接数
  {"type": "icon", "bbox": [0.040, 0.014, 0.156, 0.039], "interactivity": true, "content": "14:16 "}, // 顶部时间
  {"type": "icon", "bbox": [0.012, 0.790, 0.497, 0.906], "interactivity": true, "content": "@Kfh1LUVo 13.1 "}, // 推荐角昵称分数
  {"type": "icon", "bbox": [0.331, 0.101, 0.548, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.447, 0.934, 0.553, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.710, 0.015, 0.763, 0.038], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.766, 0.015, 0.815, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.037], "interactivity": true, "content": "AudioAudio"}, // 音频
  {"type": "icon", "bbox": [0.453, 0.058, 0.561, 0.088], "interactivity": true, "content": "Xiaohongshu"}, // 小红书
  {"type": "icon", "bbox": [0.558, 0.101, 0.745, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.160, 0.101, 0.313, 0.147], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.023, 0.057, 0.152, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.892, 0.059, 0.965, 0.095], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.301, 0.056, 0.411, 0.090], "interactivity": true, "content": "Character Designer"}, // 角色设计
  {"type": "icon", "bbox": [0.758, 0.101, 0.907, 0.150], "interactivity": true, "content": "Xiaohongshu (Xia)"}, // 小红书
  {"type": "icon", "bbox": [0.936, 0.101, 1.0, 0.149], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.014, 0.105, 0.141, 0.141], "interactivity": true, "content": "Show/HideHide&HideHide"}, // 显隐
  {"type": "icon", "bbox": [0.654, 0.938, 0.749, 0.964], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.211, 0.930, 0.387, 0.974], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.053, 0.936, 0.148, 0.967], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.853, 0.936, 0.944, 0.966], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.523, 0.899, 0.691, 0.921], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"} // Tab小红书
]
```

### 5.9 首页-综合-其他页（如有）（对应：相关图标解析.md）
- 页面描述：
  - 其他页聚焦于其他相关内容的展示，如用户反馈、设置等。
  - 布局结构包括：
    1. 顶部状态栏（时间、WiFi、通知数）
    2. 功能入口区（用户反馈、设置等）
    3. 主体内容区（相关内容列表、快捷入口等）
    4. 底部Tab栏（主功能切换）
  - 主要交互：支持相关内容浏览、设置等。
  - 典型业务流程：进入其他页→浏览相关内容→设置。
  - 主要组件：状态栏、功能按钮、Tab栏等。
- UI控件参数表：
```jsonc
[
  {"type": "icon", "bbox": [0.877, 0.015, 0.949, 0.037], "interactivity": true, "content": "48 "}, // 右上角通知
  {"type": "icon", "bbox": [0.183, 0.058, 0.257, 0.088], "interactivity": true, "content": "FM "}, // FM入口
  {"type": "icon", "bbox": [0.040, 0.014, 0.153, 0.038], "interactivity": true, "content": "14:17 "}, // 顶部时间
  {"type": "icon", "bbox": [0.448, 0.934, 0.552, 0.972], "interactivity": true, "content": "Strikethrough"}, // 格式化
  {"type": "icon", "bbox": [0.459, 0.058, 0.556, 0.087], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.768, 0.016, 0.815, 0.036], "interactivity": true, "content": "A volume control or volume indicator."}, // 音量
  {"type": "icon", "bbox": [0.824, 0.016, 0.872, 0.036], "interactivity": true, "content": "A volume control or volume indicator."}, // 音量
  {"type": "icon", "bbox": [0.711, 0.015, 0.762, 0.037], "interactivity": true, "content": "Wi-Fi connectivity"}, // Wi-Fi
  {"type": "icon", "bbox": [0.324, 0.101, 0.554, 0.148], "interactivity": true, "content": "Xiaohongshu (⌘N)"}, // 小红书快捷入口
  {"type": "icon", "bbox": [0.554, 0.101, 0.754, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.751, 0.102, 0.915, 0.149], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.157, 0.101, 0.321, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // 小红书
  {"type": "icon", "bbox": [0.309, 0.058, 0.407, 0.090], "interactivity": true, "content": "Character Design"}, // 角色设计
  {"type": "icon", "bbox": [0.897, 0.062, 0.961, 0.092], "interactivity": true, "content": "Find"}, // 搜索
  {"type": "icon", "bbox": [0.0, 0.101, 0.161, 0.149], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.024, 0.057, 0.153, 0.087], "interactivity": true, "content": "Highlight"}, // 高亮
  {"type": "icon", "bbox": [0.254, 0.936, 0.346, 0.966], "interactivity": true, "content": "Combo Box"}, // 下拉选择
  {"type": "icon", "bbox": [0.934, 0.101, 1.0, 0.148], "interactivity": true, "content": "Xray"}, // 透视
  {"type": "icon", "bbox": [0.056, 0.937, 0.146, 0.967], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"}, // Tab小红书
  {"type": "icon", "bbox": [0.638, 0.933, 0.769, 0.972], "interactivity": true, "content": "Xiaohongshu"}, // Tab小红书
  {"type": "icon", "bbox": [0.855, 0.936, 0.943, 0.966], "interactivity": true, "content": "Xiaohongshu (Little Red Book)"} // Tab小红书
]
```

### 5.x 发现页（Discover Tab）
- 页面描述：
  发现页聚焦于内容发现与分发，集成榜单、商城、分类导航、活动Banner、角色推荐、FM电台等多元内容，是用户探索新鲜内容和参与社区互动的主要入口。
- 布局结构：
  1. 顶部状态栏（时间、WiFi、网络、蓝牙、电量）
  2. 搜索栏（放大镜icon+关键词"时代少年团"）
  3. 钻石榜（钻石icon、榜单名、3头像、右箭头）
  4. 星野市集（购物袋icon、Beta、说明、右箭头）
  5. 分类导航栏（精选🔥、FM专栏New、同人、趣味、工具等Tab）
  6. 星野智能体周边首发区（大Banner、动漫角色徽章、首发限定、箭头/图标）
  7. 顶流剧本创作周区（王冠icon、标题、参与人数、描述、3角色卡片）
  8. FM古人电台区（闪电icon、标题、古画风图片、简介、作者）
  9. 底部Tab栏（首页、消息、+、发现、我的）
- 主要交互说明：
  - 搜索栏支持点击输入/跳转搜索页
  - 钻石榜、星野市集、Banner、角色卡片、FM电台等均可点击进入详情或更多内容
  - 分类导航栏Tab切换不同内容板块
  - Banner区左右箭头支持翻页或查看更多
  - 角色卡片点击查看角色详情
  - FM电台点击播放/进入详情
  - 底部Tab栏切换主功能模块，"+"号按钮支持内容添加/创作
  - 游客点击"消息""创作中心""我的"Tab弹注册/登录页

---

## 6. 尺寸规范
### 6.1 标准文件
- 标志主文件：1024×1024 PNG / SVG
- 启动页主视觉：1024×1536（竖版）、1536×1024（横版）
- 可重复背景图案：1024×1024

### 6.2 APP图标
- 原始尺寸：1024×1024
- 自动适配：512/256/128/48/32px

---

## 注意事项
- 所有文字必须使用简体中文，禁止出现繁体中文
- 标志元素不可更改，必须保持两个星星、一个笑脸/嘴巴以及右侧星星上方的眉毛
- 标志在应用中应保持在左上角45度位置，尺寸为页面比例的1/4
- 颜色系统应严格遵循规定的色值和使用比例 