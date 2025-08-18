# 星趣Vue数据看板组件库

基于 Vue 3 + TypeScript + Ant Design Vue + AntV G2Plot 构建的专业数据看板组件库，为星趣APP后台管理系统提供数据可视化解决方案。

## ✨ 特性

- 🚀 **Vue 3 + TS**: 基于最新Vue 3 Composition API和TypeScript
- 🎨 **专业设计**: 经济学人风格的简洁专业数据可视化
- 📊 **丰富图表**: 基于AntV G2Plot的多种图表类型
- ⚡ **实时数据**: WebSocket实时数据推送和更新
- 📱 **响应式**: 完整的移动端和大屏适配
- 🎯 **双屏架构**: 运营策略看板 + 商业化看板分离设计
- 🔧 **易于集成**: 完善的TypeScript类型和组件API

## 📦 安装

```bash
npm install @xingqu/vue-dashboard
# 或
yarn add @xingqu/vue-dashboard
# 或
pnpm add @xingqu/vue-dashboard
```

## 🚀 快速开始

### 1. 引入样式和组件

```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Antd from 'ant-design-vue'
import XingquVueDashboard from '@xingqu/vue-dashboard'

// 引入样式
import 'ant-design-vue/dist/antd.css'
import '@xingqu/vue-dashboard/dist/style.css'

const app = createApp(App)

app.use(createPinia())
app.use(Antd)
app.use(XingquVueDashboard)

app.mount('#app')
```

### 2. 使用完整看板

```vue
<template>
  <DashboardLayout />
</template>

<script setup lang="ts">
import { DashboardLayout } from '@xingqu/vue-dashboard'
</script>
```

### 3. 使用单个组件

```vue
<template>
  <div class="dashboard">
    <!-- 指标卡片 -->
    <MetricCard :data="metricData" @click="handleMetricClick" />
    
    <!-- 图表面板 -->
    <ChartPanel 
      title="用户增长趋势"
      chart-type="line"
      :data="chartData"
      :height="300"
      @refresh="refreshChart"
    />
    
    <!-- 筛选面板 -->
    <FilterPanel 
      v-model:filters="filters"
      @change="handleFilterChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { MetricCard, ChartPanel, FilterPanel } from '@xingqu/vue-dashboard'
import type { MetricData, ChartDataPoint, FilterOptions } from '@xingqu/vue-dashboard'

// 指标数据
const metricData = ref<MetricData>({
  key: 'dau',
  label: 'DAU',
  value: 23456,
  change: 0.125,
  changeType: 'increase',
  icon: 'user'
})

// 图表数据
const chartData = ref<ChartDataPoint[]>([
  { date: '2025-01-15', value: 20000, type: 'DAU' },
  { date: '2025-01-16', value: 21500, type: 'DAU' },
  // ... 更多数据
])

// 筛选条件
const filters = ref<FilterOptions>({
  dateRange: [dayjs().subtract(7, 'day'), dayjs()],
  department: '',
  channel: '',
  userSegment: ''
})

// 事件处理
const handleMetricClick = (data: MetricData) => {
  console.log('指标卡片点击:', data)
}

const refreshChart = () => {
  // 刷新图表数据
}

const handleFilterChange = (newFilters: FilterOptions) => {
  console.log('筛选条件变化:', newFilters)
}
</script>
```

## 📊 组件列表

### 核心组件

- **DashboardLayout** - 完整的数据看板布局
- **MetricCard** - 指标卡片组件
- **ChartPanel** - 图表容器组件
- **FilterPanel** - 筛选面板组件

### 图表组件

- **LineChart** - 折线图组件
- **FunnelChart** - 漏斗图组件（AARRR模型）
- **GaugeChart** - 仪表盘组件

### 工具函数

- **useChartTheme** - 图表主题配置
- **useRealtimeData** - 实时数据处理
- **useDashboardStore** - 状态管理

## 🎨 主题配置

### 经济学人风格主题

```typescript
import { useChartTheme } from '@xingqu/vue-dashboard'

const { economistTheme, getMetricColor, formatNumber } = useChartTheme()

// 在图表中使用主题
const chartConfig = {
  data: chartData,
  theme: economistTheme,
  color: getMetricColor('increase')
}
```

### 自定义配色

```scss
// 覆盖默认配色
:root {
  --primary-color: #1890FF;
  --success-color: #52C41A;
  --warning-color: #FAAD14;
  --error-color: #F5222D;
}
```

## 📡 实时数据

### 基本使用

```typescript
import { useRealtimeData } from '@xingqu/vue-dashboard'

const {
  data,
  isConnected,
  connectionCount,
  connect,
  disconnect
} = useRealtimeData('wss://your-websocket-url')

// 建立连接
onMounted(() => {
  connect()
})

// 断开连接
onUnmounted(() => {
  disconnect()
})
```

### 数据格式

```typescript
interface RealtimeData {
  revenue: {
    current: number
    target: number
    orders: RealtimeOrder[]
  }
  metrics: {
    paymentConversion: number
    arpu: number
    activeUsers: number
  }
  timestamp: number
}
```

## 🎯 图表类型

### 折线图

```vue
<LineChart
  :data="trendData"
  x-field="date"
  y-field="value"
  series-field="type"
  :smooth="true"
  :point="true"
  :area="false"
  :height="300"
/>
```

### 漏斗图（AARRR模型）

```vue
<FunnelChart
  :data="funnelData"
  :conversion-tag="true"
  :height="400"
  @click="handleFunnelClick"
/>
```

### 仪表盘

```vue
<GaugeChart
  :data="gaugeData"
  :height="200"
  :show-indicator="true"
  :show-axis="true"
  @change="handleGaugeChange"
/>
```

## 🔧 开发指南

### 本地开发

```bash
# 克隆项目
git clone https://github.com/xingqu/vue-dashboard.git
cd vue-dashboard

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建组件库
npm run build

# 类型检查
npm run type-check

# 代码检查
npm run lint
```

### 项目结构

```
src/
├── components/           # 通用组件
│   ├── charts/          # 图表组件
│   ├── MetricCard.vue   # 指标卡片
│   ├── ChartPanel.vue   # 图表面板
│   └── FilterPanel.vue  # 筛选面板
├── composables/         # 组合函数
│   ├── useChartTheme.ts # 图表主题
│   └── useRealtimeData.ts # 实时数据
├── stores/              # 状态管理
│   └── dashboard.ts     # 看板Store
├── styles/              # 样式文件
│   └── variables.scss   # 变量定义
├── types/               # 类型定义
│   └── dashboard.ts     # 看板类型
├── views/               # 视图组件
│   └── DashboardLayout.vue # 布局组件
└── index.ts             # 入口文件
```

## 📱 响应式设计

组件库完全支持响应式设计，适配以下断点：

- **xs**: ≤576px (手机竖屏)
- **sm**: 576-768px (手机横屏/平板竖屏)
- **md**: 768-992px (平板横屏)
- **lg**: 992-1200px (小屏电脑)
- **xl**: 1200-1600px (大屏电脑)
- **xxl**: ≥1600px (超大屏)

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

[MIT](./LICENSE) © 2025 星趣团队

## 🙏 致谢

- [Vue 3](https://vuejs.org/) - 渐进式JavaScript框架
- [Ant Design Vue](https://antdv.com/) - 企业级UI组件库
- [AntV G2Plot](https://g2plot.antv.vision/) - 统计图表库
- [The Economist](https://www.economist.com/) - 图表设计灵感来源

---

如有问题，请提交 [Issue](https://github.com/xingqu/vue-dashboard/issues) 或联系开发团队。