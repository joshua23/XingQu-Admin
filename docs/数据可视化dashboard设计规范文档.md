# 星趣APP数据看板设计规范文档

> 基于Vue 3 + Ant Design Vue + AntV G2Plot技术栈的后台管理系统数据看板完整设计规范

---

## 文档信息

- **文档版本**: v1.0.0
- **创建时间**: 2025年1月
- **设计师**: 星趣UI/UX团队
- **技术栈**: Vue 3 + TypeScript + Ant Design Vue 4.x + AntV G2Plot
- **适用范围**: 前端开发团队、后端开发团队
- **文档状态**: 已确认

---

## 目录

1. [设计系统概览](#1-设计系统概览)
2. [设计令牌与样式](#2-设计令牌与样式)
3. [组件库规范](#3-组件库规范)
4. [图表规范](#4-图表规范)
5. [布局规范](#5-布局规范)
6. [交互规范](#6-交互规范)
7. [响应式设计](#7-响应式设计)
8. [开发实施指南](#8-开发实施指南)

---

## 1. 设计系统概览

### 1.1 设计理念

- **数据为王**：所有设计决策服务于数据可读性和决策效率
- **经济学人风格**：简洁克制的视觉语言，专业的信息传达
- **实时响应**：商业化数据实时刷新，运营数据T+1更新
- **双屏架构**：运营策略看板 + 商业化看板分离设计

### 1.2 页面架构

```
数据看板系统架构
├── 运营策略看板 (T+1更新)
│   ├── 核心指标卡片 (DAU/新增/留存/时长)
│   ├── AARRR漏斗分析
│   ├── 用户增长趋势
│   └── 功能使用分析
└── 商业化看板 (实时更新)
    ├── 实时收入监控
    ├── 会员体系分析  
    ├── 星川经济数据
    └── 广告变现指标
```

---

## 2. 设计令牌与样式

### 2.1 色彩系统

#### 主色彩 (Primary Colors)
```scss
// 主品牌色
$primary-color: #1890FF;
$primary-1: #E6F7FF;
$primary-6: #1890FF;  // 标准蓝
$primary-7: #096DD9;  // 深蓝

// 功能色彩
$success-color: #52C41A;  // 成功/增长
$warning-color: #FAAD14;  // 警告/关注  
$error-color: #F5222D;    // 错误/下降
$info-color: #13C2C2;     // 信息/中性
```

#### 语义化配色
```scss
// 数据指标配色
$metric-positive: #52C41A;    // 正向指标 ↑
$metric-negative: #F5222D;    // 负向指标 ↓
$metric-neutral: #8C8C8C;     // 中性指标 →

// AARRR漏斗配色
$aarrr-acquisition: #1890FF;  // 获取
$aarrr-activation: #13C2C2;   // 激活
$aarrr-retention: #52C41A;    // 留存
$aarrr-revenue: #FAAD14;      // 收入
$aarrr-referral: #722ED1;     // 推荐
```

#### 中性色阶
```scss
$gray-1: #FFFFFF;   // 卡片背景
$gray-2: #FAFAFA;   // 页面背景
$gray-3: #F5F5F5;   // 分割线
$gray-4: #F0F0F0;   // 边框
$gray-5: #D9D9D9;   // 禁用状态
$gray-6: #BFBFBF;   // 辅助文字
$gray-7: #8C8C8C;   // 次要文字
$gray-8: #595959;   // 正文文字
$gray-9: #434343;   // 标题文字
$gray-10: #262626;  // 主标题
$gray-11: #1F1F1F;  // 重要数字
$gray-12: #141414;  // 黑色文字
```

### 2.2 字体系统

#### 字体族
```css
/* 系统字体栈 */
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
             'Helvetica Neue', Arial, 'Noto Sans', sans-serif,
             'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 
             'Noto Color Emoji';

/* 数字字体 (等宽) */
font-family: 'SF Mono', Monaco, Inconsolata, 'Roboto Mono', 
             'Source Code Pro', Menlo, Consolas, 'Courier New', monospace;
```

#### 字体规格表
| 用途 | 字号 | 行高 | 字重 | 颜色 | CSS类名 |
|------|------|------|------|------|---------|
| 大标题 | 24px | 32px | 600 | #262626 | `.title-large` |
| 中标题 | 20px | 28px | 600 | #262626 | `.title-medium` |
| 小标题 | 16px | 24px | 500 | #262626 | `.title-small` |
| 正文 | 14px | 22px | 400 | #595959 | `.text-body` |
| 辅助文字 | 12px | 20px | 400 | #8C8C8C | `.text-caption` |
| 数据大字 | 32px | 40px | 600 | #262626 | `.number-large` |
| 数据中字 | 24px | 32px | 500 | #262626 | `.number-medium` |
| 数据小字 | 16px | 24px | 400 | #262626 | `.number-small` |

### 2.3 间距系统

```scss
// 基础间距单位 4px
$spacing-1: 4px;   // 微小间距
$spacing-2: 8px;   // 小间距  
$spacing-3: 12px;  // 常规间距
$spacing-4: 16px;  // 中等间距
$spacing-5: 20px;  // 大间距
$spacing-6: 24px;  // 超大间距
$spacing-8: 32px;  // 区块间距
$spacing-12: 48px; // 页面间距

// 组件内边距
$card-padding: 24px;
$panel-padding: 16px;
$button-padding: 8px 16px;
```

### 2.4 阴影系统

```scss
// 卡片阴影
$shadow-card: 0 2px 8px rgba(0, 0, 0, 0.06);
$shadow-card-hover: 0 4px 16px rgba(0, 0, 0, 0.12);

// 面板阴影
$shadow-panel: 0 1px 3px rgba(0, 0, 0, 0.1);
$shadow-dropdown: 0 4px 12px rgba(0, 0, 0, 0.15);

// 模态框阴影
$shadow-modal: 0 8px 32px rgba(0, 0, 0, 0.2);
```

---

## 3. 组件库规范

### 3.1 核心指标卡片 (MetricCard)

#### Vue组件结构
```vue
<template>
  <a-card class="metric-card" :hoverable="true">
    <div class="metric-icon">
      <component :is="iconComponent" />
    </div>
    <div class="metric-content">
      <div class="metric-label">{{ label }}</div>
      <div class="metric-value">{{ formattedValue }}</div>
      <div class="metric-change" :class="changeClass">
        <Icon :type="changeIcon" />
        {{ changeText }}
      </div>
    </div>
  </a-card>
</template>

<script setup lang="ts">
interface Props {
  label: string
  value: number | string
  change?: number
  changeType?: 'increase' | 'decrease' | 'neutral'
  icon?: string
  suffix?: string
}
</script>
```

#### 样式规范
```scss
.metric-card {
  padding: 24px;
  border-radius: 8px;
  border: 1px solid #F0F0F0;
  background: #FFFFFF;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  transition: all 0.3s ease;
  
  &:hover {
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
    transform: translateY(-2px);
  }
  
  .metric-icon {
    font-size: 20px;
    color: #8C8C8C;
    margin-bottom: 12px;
  }
  
  .metric-label {
    font-size: 14px;
    color: #8C8C8C;
    margin-bottom: 8px;
  }
  
  .metric-value {
    font-size: 32px;
    font-weight: 600;
    color: #262626;
    font-variant-numeric: tabular-nums;
    margin-bottom: 8px;
  }
  
  .metric-change {
    font-size: 14px;
    display: flex;
    align-items: center;
    gap: 4px;
    
    &.positive {
      color: #52C41A;
    }
    
    &.negative {
      color: #F5222D;
    }
    
    &.neutral {
      color: #8C8C8C;
    }
  }
}
```

### 3.2 数据表格 (DataTable)

#### AntD表格配置
```typescript
// 表格通用配置
const tableConfig = {
  pagination: {
    showSizeChanger: true,
    showQuickJumper: true,
    showTotal: (total: number) => `共 ${total} 条`,
    pageSizeOptions: ['10', '20', '50', '100']
  },
  scroll: { x: 800 },
  size: 'middle' as const,
  bordered: false,
  rowClassName: (record: any, index: number) => 
    index % 2 === 0 ? 'table-row-even' : 'table-row-odd'
}

// 列定义示例
const columns = [
  {
    title: '时间',
    dataIndex: 'date',
    key: 'date',
    width: 120,
    sorter: true,
    render: (date: string) => dayjs(date).format('MM-DD')
  },
  {
    title: 'DAU',
    dataIndex: 'dau',
    key: 'dau',
    align: 'right' as const,
    sorter: true,
    render: (value: number) => value.toLocaleString()
  },
  {
    title: '变化率',
    dataIndex: 'changeRate',
    key: 'changeRate',
    align: 'right' as const,
    render: (rate: number) => (
      <span className={rate > 0 ? 'text-success' : 'text-error'}>
        {rate > 0 ? '+' : ''}{rate.toFixed(1)}%
      </span>
    )
  }
]
```

### 3.3 筛选器组件 (FilterPanel)

#### 组件结构
```vue
<template>
  <div class="filter-panel">
    <a-space>
      <!-- 时间选择器 -->
      <a-range-picker
        v-model:value="dateRange"
        :presets="datePresets"
        @change="onDateChange"
      />
      
      <!-- 部门筛选 -->
      <a-select
        v-model:value="department"
        placeholder="选择部门"
        style="width: 120px"
      >
        <a-select-option value="">全部部门</a-select-option>
        <a-select-option value="ops">运营</a-select-option>
        <a-select-option value="dev">技术</a-select-option>
      </a-select>
      
      <!-- 更多操作 -->
      <a-dropdown>
        <a-button>
          <MoreOutlined />
        </a-button>
        <template #overlay>
          <a-menu @click="onMenuClick">
            <a-menu-item key="export">导出数据</a-menu-item>
            <a-menu-item key="drill">数据下钻</a-menu-item>
            <a-menu-item key="detail">详情查看</a-menu-item>
          </a-menu>
        </template>
      </a-dropdown>
    </a-space>
  </div>
</template>
```

#### 预设时间范围
```typescript
const datePresets = [
  { label: '今日', value: [dayjs().startOf('day'), dayjs().endOf('day')] },
  { label: '昨日', value: [dayjs().subtract(1, 'day').startOf('day'), dayjs().subtract(1, 'day').endOf('day')] },
  { label: '最近7天', value: [dayjs().subtract(7, 'day'), dayjs()] },
  { label: '最近30天', value: [dayjs().subtract(30, 'day'), dayjs()] },
  { label: '本月', value: [dayjs().startOf('month'), dayjs().endOf('month')] }
]
```

---

## 4. 图表规范

### 4.1 AntV G2Plot通用配置

#### 基础配置
```typescript
// 图表通用主题配置
const chartTheme = {
  defaultColor: '#1890FF',
  colors10: [
    '#1890FF', '#52C41A', '#FAAD14', '#F5222D', '#722ED1',
    '#13C2C2', '#FA8C16', '#A0D911', '#EB2F96', '#F759AB'
  ],
  
  // 几何图形样式
  geometries: {
    interval: {
      rect: {
        default: { fill: '#1890FF', stroke: '#1890FF', lineWidth: 0 },
        active: { stroke: '#1890FF', lineWidth: 1 },
        inactive: { fillOpacity: 0.3, strokeOpacity: 0.3 }
      }
    },
    line: {
      line: {
        default: { stroke: '#1890FF', lineWidth: 2, strokeOpacity: 1 },
        active: { lineWidth: 3 },
        inactive: { strokeOpacity: 0.3 }
      },
      point: {
        default: { fill: '#1890FF', r: 3, stroke: '#fff', lineWidth: 1 },
        active: { r: 4, stroke: '#1890FF', lineWidth: 2 },
        inactive: { fillOpacity: 0.3, strokeOpacity: 0.3 }
      }
    }
  },
  
  // 坐标轴样式
  axis: {
    common: {
      title: {
        style: {
          fontSize: 12,
          fill: '#8C8C8C',
          fontWeight: 400
        }
      },
      label: {
        style: {
          fontSize: 12,
          fill: '#595959'
        }
      },
      line: {
        style: {
          stroke: '#F0F0F0',
          lineWidth: 1
        }
      },
      tickLine: {
        style: {
          stroke: '#F0F0F0',
          lineWidth: 1,
          length: 4
        }
      },
      grid: {
        line: {
          style: {
            stroke: '#F0F0F0',
            lineWidth: 1,
            lineDash: [0, 0]
          }
        }
      }
    }
  },
  
  // 图例样式
  legend: {
    common: {
      marker: {
        style: {
          r: 4
        }
      },
      text: {
        style: {
          fontSize: 12,
          fill: '#595959'
        }
      }
    }
  }
}
```

### 4.2 具体图表实现

#### 折线图 - 趋势分析
```typescript
// UserTrendChart.vue
const lineConfig = {
  data: trendData.value,
  xField: 'date',
  yField: 'value',
  seriesField: 'type',
  
  // 样式配置
  color: ['#1890FF', '#52C41A', '#FAAD14'],
  lineStyle: {
    lineWidth: 2
  },
  point: {
    size: 3,
    shape: 'circle',
    style: {
      fill: 'white',
      stroke: '#1890FF',
      lineWidth: 2
    }
  },
  
  // 坐标轴
  xAxis: {
    type: 'time',
    tickCount: 7,
    label: {
      formatter: (text: string) => dayjs(text).format('MM/DD')
    }
  },
  yAxis: {
    label: {
      formatter: (v: string) => `${parseInt(v) / 1000}K`
    }
  },
  
  // 交互
  tooltip: {
    shared: true,
    showCrosshairs: true,
    formatter: (datum: any) => ({
      name: datum.type,
      value: datum.value.toLocaleString()
    })
  },
  
  // 动画
  animation: {
    appear: {
      animation: 'path-in',
      duration: 1000
    }
  }
}
```

#### 漏斗图 - AARRR模型
```typescript
// FunnelChart.vue  
const funnelConfig = {
  data: funnelData.value,
  xField: 'stage',
  yField: 'value',
  
  // 颜色映射
  color: ({ stage }: any) => {
    const colorMap = {
      'Acquisition': '#1890FF',
      'Activation': '#13C2C2', 
      'Retention': '#52C41A',
      'Revenue': '#FAAD14',
      'Referral': '#722ED1'
    }
    return colorMap[stage] || '#1890FF'
  },
  
  // 标签显示
  label: {
    content: (data: any) => `${data.stage}\n${data.value.toLocaleString()} (${data.rate}%)`,
    style: {
      fontSize: 12,
      fill: '#fff',
      fontWeight: 500
    }
  },
  
  // 漏斗样式
  funnelStyle: {
    stroke: '#fff',
    lineWidth: 2
  },
  
  // 转化率连接线
  conversionTag: {
    visible: true,
    formatter: (meta: any) => `${meta.$conversionRate$}%`
  }
}
```

#### 仪表盘 - 实时监控
```typescript
// GaugeChart.vue
const gaugeConfig = {
  percent: progressPercent.value,
  range: {
    ticks: [0, 1/3, 2/3, 1],
    color: ['#F5222D', '#FAAD14', '#1890FF', '#52C41A']
  },
  
  // 指标文本
  indicator: {
    pointer: {
      style: {
        stroke: '#D0D0D0'
      }
    },
    pin: {
      style: {
        stroke: '#D0D0D0'
      }
    }
  },
  
  // 刻度
  axis: {
    label: {
      formatter: (v: string) => `${(Number(v) * 100).toFixed(0)}%`
    },
    subTickLine: {
      count: 3
    }
  },
  
  // 统计文本
  statistic: {
    content: {
      style: {
        fontSize: '32px',
        fontWeight: 600,
        color: '#262626'
      },
      formatter: () => `${(progressPercent.value * 100).toFixed(1)}%`
    },
    title: {
      content: '目标完成度'
    }
  }
}
```

### 4.3 图表容器规范

```scss
// 图表容器通用样式
.chart-container {
  background: #fff;
  border-radius: 8px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  
  .chart-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    
    .chart-title {
      font-size: 16px;
      font-weight: 500;
      color: #262626;
    }
    
    .chart-extra {
      display: flex;
      gap: 8px;
    }
  }
  
  .chart-content {
    min-height: 300px;
    position: relative;
    
    // 加载状态
    &.loading {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    // 空数据状态  
    &.empty {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #8C8C8C;
    }
  }
}
```

---

## 5. 布局规范

### 5.1 网格系统

#### 基础网格
```scss
// 24栅格系统 (基于AntD)
.dashboard-layout {
  padding: 24px;
  
  // 核心指标行
  .metrics-row {
    margin-bottom: 24px;
    
    .a-col {
      padding: 0 12px;
    }
  }
  
  // 图表区域
  .charts-section {
    .chart-row {
      margin-bottom: 24px;
      
      .chart-col {
        padding: 0 12px;
      }
    }
  }
}
```

#### 响应式断点
```typescript
// 断点配置
const breakpoints = {
  xs: { span: 24 },        // <576px
  sm: { span: 12 },        // ≥576px  
  md: { span: 8 },         // ≥768px
  lg: { span: 6 },         // ≥992px
  xl: { span: 6 },         // ≥1200px
  xxl: { span: 6 }         // ≥1600px
}

// 核心指标卡片响应式
<a-col v-bind="breakpoints">
  <MetricCard :data="metric" />
</a-col>
```

### 5.2 页面布局模板

#### 运营看板布局
```vue
<template>
  <div class="dashboard-container">
    <!-- 页面头部 -->
    <div class="dashboard-header">
      <div class="header-left">
        <h1 class="page-title">运营策略看板</h1>
        <div class="update-time">最后更新: {{ updateTime }}</div>
      </div>
      <div class="header-right">
        <FilterPanel v-model="filters" />
      </div>
    </div>
    
    <!-- 核心指标 -->
    <a-row :gutter="24" class="metrics-row">
      <a-col :xs="24" :sm="12" :lg="6" v-for="metric in coreMetrics" :key="metric.key">
        <MetricCard :data="metric" />
      </a-col>
    </a-row>
    
    <!-- 趋势图表 -->
    <a-row :gutter="24" class="charts-row">
      <a-col :xs="24" :lg="12">
        <ChartPanel title="用户增长趋势">
          <UserTrendChart :data="trendData" />
        </ChartPanel>
      </a-col>
      <a-col :xs="24" :lg="12">
        <ChartPanel title="留存率分析">
          <RetentionChart :data="retentionData" />
        </ChartPanel>
      </a-col>
    </a-row>
    
    <!-- 漏斗分析 -->
    <a-row :gutter="24">
      <a-col :span="24">
        <ChartPanel title="AARRR海盗模型">
          <FunnelChart :data="funnelData" />
        </ChartPanel>
      </a-col>
    </a-row>
    
    <!-- 详细数据 -->
    <a-row :gutter="24">
      <a-col :span="24">
        <TablePanel title="详细数据">
          <DataTable :columns="tableColumns" :data="tableData" />
        </TablePanel>
      </a-col>
    </a-row>
  </div>
</template>
```

### 5.3 Tab切换布局

```vue
<template>
  <div class="dashboard-tabs">
    <a-tabs v-model:activeKey="activeTab" size="large">
      <a-tab-pane key="operations" tab="运营策略看板">
        <OperationsDashboard />
      </a-tab-pane>
      
      <a-tab-pane key="revenue" tab="商业化看板">
        <RevenueDashboard />
        <div class="live-indicator">
          <span class="live-dot"></span>
          实时刷新
        </div>
      </a-tab-pane>
    </a-tabs>
  </div>
</template>

<style scoped>
.live-indicator {
  position: absolute;
  top: 16px;
  right: 24px;
  font-size: 12px;
  color: #52C41A;
  display: flex;
  align-items: center;
  gap: 4px;
  
  .live-dot {
    width: 6px;
    height: 6px;
    background: #52C41A;
    border-radius: 50%;
    animation: pulse 1.5s infinite;
  }
}

@keyframes pulse {
  0% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.2); }
  100% { opacity: 1; transform: scale(1); }
}
</style>
```

---

## 6. 交互规范

### 6.1 数据刷新机制

#### 实时数据处理
```typescript
// 商业化数据实时更新
const useRealtimeData = () => {
  const { data, isLoading } = useWebSocket('/api/realtime/revenue', {
    immediate: true,
    autoReconnect: {
      retries: 3,
      delay: 1000
    }
  })
  
  // 数据变化动画
  const animateChange = (newValue: number, oldValue: number) => {
    if (newValue !== oldValue) {
      // 触发数字动画
      countUp(oldValue, newValue, 800)
      // 背景闪烁提示
      flashBackground('#E6F7FF', 1000)
    }
  }
  
  return { data, isLoading, animateChange }
}
```

#### T+1数据更新
```typescript
// 运营数据定时更新
const useScheduledData = () => {
  const { data, refresh } = useFetch('/api/operations/daily')
  
  // 每小时检查更新
  useIntervalFn(() => {
    refresh()
  }, 60 * 60 * 1000)
  
  return { data, refresh }
}
```

### 6.2 下钻交互

#### 数据下钻组件
```vue
<template>
  <a-modal
    v-model:visible="visible"
    title="数据详情"
    width="800px"
    :footer="null"
  >
    <div class="drill-content">
      <!-- 指标概要 -->
      <div class="metric-summary">
        <h3>{{ metric.name }}</h3>
        <div class="metric-value">{{ metric.value }}</div>
        <div class="metric-comparison">
          <span>环比: {{ metric.periodOverPeriod }}%</span>
          <span>同比: {{ metric.yearOverYear }}%</span>
        </div>
      </div>
      
      <!-- 构成分析 -->
      <div class="composition-analysis">
        <h4>构成分析</h4>
        <a-table 
          :columns="compositionColumns"
          :data-source="compositionData"
          :pagination="false"
        />
      </div>
      
      <!-- 趋势分析 -->
      <div class="trend-analysis">
        <h4>趋势分析</h4>
        <Line v-bind="trendConfig" />
      </div>
      
      <!-- 操作按钮 -->
      <div class="actions">
        <a-space>
          <a-button @click="exportData">导出数据</a-button>
          <a-button @click="viewMore">查看更多</a-button>
          <a-button type="primary" @click="close">关闭</a-button>
        </a-space>
      </div>
    </div>
  </a-modal>
</template>
```

### 6.3 筛选交互

#### 筛选状态管理
```typescript
// 筛选器状态
const filters = reactive({
  dateRange: [dayjs().subtract(7, 'day'), dayjs()],
  department: '',
  channel: '',
  userSegment: ''
})

// 筛选联动
const cascadingFilters = computed(() => {
  return {
    // 根据部门过滤渠道选项
    channels: getChannelsByDepartment(filters.department),
    // 根据时间范围调整用户分群
    userSegments: getUserSegmentsByDateRange(filters.dateRange)
  }
})

// 筛选结果
const filteredData = computed(() => {
  return applyFilters(rawData.value, filters)
})
```

---

## 7. 响应式设计

### 7.1 断点定义

```scss
// 媒体查询断点
$breakpoint-xs: 575.98px;   // 手机竖屏
$breakpoint-sm: 767.98px;   // 手机横屏/平板竖屏  
$breakpoint-md: 991.98px;   // 平板横屏
$breakpoint-lg: 1199.98px;  // 小屏电脑
$breakpoint-xl: 1599.98px;  // 大屏电脑
$breakpoint-xxl: 1600px;    // 超大屏

// 响应式混合宏
@mixin respond-to($breakpoint) {
  @if $breakpoint == xs {
    @media (max-width: $breakpoint-xs) { @content; }
  }
  @if $breakpoint == sm {
    @media (min-width: #{$breakpoint-xs + 1px}) and (max-width: $breakpoint-sm) { @content; }
  }
  @if $breakpoint == md {
    @media (min-width: #{$breakpoint-sm + 1px}) and (max-width: $breakpoint-md) { @content; }
  }
  @if $breakpoint == lg {
    @media (min-width: #{$breakpoint-md + 1px}) and (max-width: $breakpoint-lg) { @content; }
  }
  @if $breakpoint == xl {
    @media (min-width: #{$breakpoint-lg + 1px}) and (max-width: $breakpoint-xl) { @content; }
  }
  @if $breakpoint == xxl {
    @media (min-width: #{$breakpoint-xxl}) { @content; }
  }
}
```

### 7.2 组件响应式适配

#### 指标卡片响应式
```scss
.metric-card {
  // 默认样式 (桌面端)
  padding: 24px;
  
  .metric-value {
    font-size: 32px;
  }
  
  // 平板适配
  @include respond-to(md) {
    padding: 20px;
    
    .metric-value {
      font-size: 28px;
    }
  }
  
  // 手机适配
  @include respond-to(xs) {
    padding: 16px;
    
    .metric-value {
      font-size: 24px;
    }
    
    .metric-change {
      font-size: 12px;
    }
  }
}
```

#### 图表响应式配置
```typescript
// 图表响应式高度
const getChartHeight = () => {
  const screenWidth = window.innerWidth
  
  if (screenWidth < 576) return 200      // 手机
  if (screenWidth < 768) return 250      // 平板竖屏
  if (screenWidth < 992) return 300      // 平板横屏
  if (screenWidth < 1200) return 350     // 小屏电脑
  return 400                             // 大屏电脑
}

// 图表响应式配置
const responsiveConfig = {
  height: getChartHeight(),
  appendPadding: [10, 10, 10, 10],
  
  // 响应式字体
  xAxis: {
    label: {
      style: {
        fontSize: window.innerWidth < 768 ? 10 : 12
      }
    }
  },
  
  // 响应式图例
  legend: {
    position: window.innerWidth < 768 ? 'bottom' : 'top'
  }
}
```

### 7.3 布局响应式策略

| 屏幕尺寸 | 核心指标 | 图表布局 | 侧边栏 | 字体调整 |
|---------|----------|----------|--------|----------|
| 超大屏(≥1600px) | 4列 | 3列 | 展开 | 标准 |
| 大屏(1200-1599px) | 4列 | 2列 | 展开 | 标准 |
| 中屏(992-1199px) | 2列 | 2列 | 收起 | 标准 |
| 小屏(768-991px) | 2列 | 1列 | 隐藏 | 缩小 |
| 手机(≤767px) | 1列 | 1列 | 隐藏 | 缩小 |

---

## 8. 开发实施指南

### 8.1 项目结构

```
src/
├── components/           # 通用组件
│   ├── charts/          # 图表组件
│   │   ├── LineChart.vue
│   │   ├── FunnelChart.vue
│   │   └── GaugeChart.vue
│   ├── dashboard/       # 看板组件
│   │   ├── MetricCard.vue
│   │   ├── FilterPanel.vue
│   │   └── DataTable.vue
│   └── common/          # 基础组件
├── views/               # 页面视图
│   ├── dashboard/
│   │   ├── OperationsDashboard.vue
│   │   └── RevenueDashboard.vue
├── composables/         # 组合式函数
│   ├── useChartTheme.ts
│   ├── useRealtimeData.ts
│   └── useFilters.ts
├── utils/               # 工具函数
│   ├── formatters.ts    # 数据格式化
│   └── chartHelpers.ts  # 图表辅助
└── styles/              # 样式文件
    ├── variables.scss   # 设计令牌
    ├── mixins.scss      # 混合宏
    └── dashboard.scss   # 看板样式
```

### 8.2 核心依赖

```json
{
  "dependencies": {
    "vue": "^3.3.0",
    "@ant-design/icons-vue": "^7.0.0",
    "ant-design-vue": "^4.0.0",
    "@antv/g2plot": "^2.4.0",
    "dayjs": "^1.11.0",
    "@vueuse/core": "^10.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "sass": "^1.60.0",
    "typescript": "^5.0.0",
    "vite": "^4.0.0"
  }
}
```

### 8.3 样式架构

```scss
// styles/index.scss - 主样式文件

// 1. 设计令牌
@import './variables.scss';

// 2. 混合宏
@import './mixins.scss'; 

// 3. 基础样式
@import './base.scss';

// 4. 组件样式
@import './components/metric-card.scss';
@import './components/chart-panel.scss';
@import './components/filter-panel.scss';

// 5. 页面样式  
@import './dashboard.scss';

// 6. 响应式样式
@import './responsive.scss';

// 7. 工具类
@import './utilities.scss';
```

### 8.4 类型定义

```typescript
// types/dashboard.ts

// 指标数据类型
export interface MetricData {
  label: string
  value: number | string
  change?: number
  changeType?: 'increase' | 'decrease' | 'neutral'
  icon?: string
  suffix?: string
  prefix?: string
}

// 图表数据类型
export interface ChartDataPoint {
  date: string
  value: number
  type?: string
  [key: string]: any
}

// 漏斗数据类型
export interface FunnelData {
  stage: string
  value: number
  rate: number
  conversion?: number
}

// 筛选器类型
export interface FilterOptions {
  dateRange: [Dayjs, Dayjs]
  department: string
  channel: string
  userSegment: string
}

// API响应类型
export interface ApiResponse<T> {
  code: number
  data: T
  message: string
  timestamp: number
}
```

### 8.5 主题配置

```typescript
// config/theme.ts - AntD主题配置

import type { ThemeConfig } from 'ant-design-vue/es/config-provider/context'

export const dashboardTheme: ThemeConfig = {
  token: {
    // 基础令牌
    colorPrimary: '#1890FF',
    colorSuccess: '#52C41A',
    colorWarning: '#FAAD14', 
    colorError: '#F5222D',
    colorInfo: '#13C2C2',
    
    // 字体
    fontFamily: '-apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, \'Helvetica Neue\', Arial, \'Noto Sans\', sans-serif',
    fontSize: 14,
    fontSizeLG: 16,
    fontSizeXL: 20,
    
    // 间距
    padding: 16,
    paddingLG: 24,
    paddingXL: 32,
    
    // 圆角
    borderRadius: 8,
    borderRadiusLG: 12,
    
    // 阴影
    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.06)',
    boxShadowSecondary: '0 4px 16px rgba(0, 0, 0, 0.12)'
  },
  
  components: {
    Card: {
      colorBorderSecondary: '#F0F0F0',
      paddingLG: 24
    },
    
    Table: {
      headerBg: '#FAFAFA',
      headerSplitColor: '#F0F0F0',
      bodySortBg: '#FAFAFA'
    },
    
    Tabs: {
      cardPaddingSM: '8px 16px',
      titleFontSize: 16
    }
  }
}
```

### 8.6 性能优化建议

#### 图表性能优化
```typescript
// 大数据集处理
const optimizeChartData = (data: any[], maxPoints: number = 100) => {
  if (data.length <= maxPoints) return data
  
  // 数据采样算法
  const step = Math.ceil(data.length / maxPoints)
  return data.filter((_, index) => index % step === 0)
}

// 图表懒加载
const { target, isIntersecting } = useIntersectionObserver()
const shouldRenderChart = computed(() => isIntersecting.value)
```

#### 内存管理
```typescript
// 组件销毁时清理定时器
onUnmounted(() => {
  if (realtimeTimer) {
    clearInterval(realtimeTimer)
  }
  
  if (websocketConnection) {
    websocketConnection.close()
  }
})
```

---

## 9. 交付清单

### 9.1 设计交付物

- [x] 设计规范文档 (本文档)
- [x] 视觉设计稿 (文字原型)
- [x] 组件规范说明
- [x] 图表配置示例  
- [x] 响应式适配方案
- [x] 交互流程说明

### 9.2 开发支持

- [x] Vue组件结构示例
- [x] TypeScript类型定义
- [x] AntD主题配置
- [x] AntV图表配置
- [x] SCSS样式规范
- [x] 项目结构建议

### 9.3 后续迭代

1. **视觉优化**：根据实际数据效果调整配色和布局
2. **交互增强**：添加更多数据下钻和分析功能  
3. **性能优化**：大数据量场景下的渲染优化
4. **功能扩展**：添加自定义看板和指标配置

---

## 附录

### A. 设计资源

- AntD官方设计语言: https://ant.design/docs/spec/introduce-cn
- AntV可视化规范: https://antv.vision/zh/docs/specification/principles/basic
- 经济学人图表指南: https://design-system.economist.com/

### B. 技术参考

- Vue 3文档: https://cn.vuejs.org/
- AntD Vue组件库: https://antdv.com/
- G2Plot图表库: https://g2plot.antv.vision/

---

*本设计规范文档将根据开发进度和用户反馈持续优化更新。*