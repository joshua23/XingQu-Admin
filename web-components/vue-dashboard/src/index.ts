// 星趣Vue数据看板组件库入口文件
import type { App } from 'vue'

// 导入主要组件
import DashboardLayout from './views/DashboardLayout.vue'
import MetricCard from './components/MetricCard.vue'
import ChartPanel from './components/ChartPanel.vue'
import FilterPanel from './components/FilterPanel.vue'

// 导入图表组件
import LineChart from './components/charts/LineChart.vue'
import FunnelChart from './components/charts/FunnelChart.vue'
import GaugeChart from './components/charts/GaugeChart.vue'

// 导入Composables
import { useChartTheme } from './composables/useChartTheme'
import { useRealtimeData } from './composables/useRealtimeData'

// 导入Store
import { useDashboardStore } from './stores/dashboard'

// 导入类型定义
export type * from './types/dashboard'

// 导入样式
import './styles/variables.scss'

// 组件列表
const components = [
  DashboardLayout,
  MetricCard,
  ChartPanel,
  FilterPanel,
  LineChart,
  FunnelChart,
  GaugeChart
]

// 组件注册函数
const install = (app: App) => {
  // 注册所有组件
  components.forEach(component => {
    if (component.name) {
      app.component(component.name, component)
    }
  })
  
  // 注册全局属性（可选）
  app.config.globalProperties.$dashboard = {
    version: '1.0.0',
    name: '星趣数据看板'
  }
}

// 默认导出（用于插件形式安装）
const XingquVueDashboard = {
  install,
  version: '1.0.0'
}

// 导出组件和工具
export {
  // 主要组件
  DashboardLayout,
  MetricCard,
  ChartPanel,
  FilterPanel,
  
  // 图表组件
  LineChart,
  FunnelChart,
  GaugeChart,
  
  // Composables
  useChartTheme,
  useRealtimeData,
  
  // Store
  useDashboardStore,
  
  // 安装函数
  install
}

// 默认导出
export default XingquVueDashboard