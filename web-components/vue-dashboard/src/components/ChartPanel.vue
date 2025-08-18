<template>
  <a-card 
    class="chart-panel" 
    :class="[
      `chart-panel--${chartType}`,
      { 'chart-panel--loading': loading }
    ]"
    :loading="loading"
  >
    <!-- 图表头部 -->
    <template #title>
      <div class="chart-panel__header">
        <div class="chart-panel__title">
          <span class="chart-panel__title-text">{{ title }}</span>
          <a-badge 
            v-if="realtime" 
            status="processing" 
            text="实时" 
            class="chart-panel__realtime"
          />
        </div>
        
        <div class="chart-panel__extra" v-if="$slots.extra || showActions">
          <slot name="extra">
            <a-space size="small" v-if="showActions">
              <!-- 刷新按钮 -->
              <a-tooltip title="刷新数据">
                <a-button 
                  type="text" 
                  size="small"
                  :loading="refreshing"
                  @click="handleRefresh"
                >
                  <template #icon>
                    <ReloadOutlined />
                  </template>
                </a-button>
              </a-tooltip>
              
              <!-- 下钻按钮 -->
              <a-tooltip title="数据下钻">
                <a-button 
                  type="text" 
                  size="small"
                  @click="handleDrillDown"
                >
                  <template #icon>
                    <ZoomInOutlined />
                  </template>
                </a-button>
              </a-tooltip>
              
              <!-- 更多操作 -->
              <a-dropdown>
                <a-button type="text" size="small">
                  <template #icon>
                    <MoreOutlined />
                  </template>
                </a-button>
                <template #overlay>
                  <a-menu @click="handleMenuClick">
                    <a-menu-item key="export-png">
                      <FileImageOutlined />
                      导出图片
                    </a-menu-item>
                    <a-menu-item key="export-data">
                      <FileExcelOutlined />
                      导出数据
                    </a-menu-item>
                    <a-menu-divider />
                    <a-menu-item key="fullscreen">
                      <FullscreenOutlined />
                      全屏查看
                    </a-menu-item>
                  </a-menu>
                </template>
              </a-dropdown>
            </a-space>
          </slot>
        </div>
      </div>
    </template>
    
    <!-- 图表内容区域 -->
    <div 
      class="chart-panel__content"
      :style="{ height: contentHeight }"
    >
      <!-- 空数据状态 -->
      <div v-if="!loading && (!data || data.length === 0)" class="chart-panel__empty">
        <a-empty 
          description="暂无数据"
          :image="Empty.PRESENTED_IMAGE_SIMPLE"
        >
          <a-button type="primary" @click="handleRefresh">重新加载</a-button>
        </a-empty>
      </div>
      
      <!-- 图表渲染区域 -->
      <div 
        v-else-if="!loading"
        ref="chartContainer"
        class="chart-panel__chart"
        :style="{ height: '100%' }"
      />
      
      <!-- 错误状态 -->
      <div v-if="error" class="chart-panel__error">
        <a-result
          status="error"
          title="图表加载失败"
          :sub-title="error"
        >
          <template #extra>
            <a-button type="primary" @click="handleRefresh">重试</a-button>
          </template>
        </a-result>
      </div>
    </div>
  </a-card>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Empty } from 'ant-design-vue'
import {
  ReloadOutlined,
  ZoomInOutlined,
  MoreOutlined,
  FileImageOutlined,
  FileExcelOutlined,
  FullscreenOutlined
} from '@ant-design/icons-vue'
import type { ChartConfig } from '../types/dashboard'

// Props定义
interface Props {
  title: string
  data: any[]
  chartType: 'line' | 'column' | 'pie' | 'funnel' | 'gauge'
  config?: ChartConfig
  loading?: boolean
  height?: number | string
  realtime?: boolean
  showActions?: boolean
  error?: string
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  height: 300,
  realtime: false,
  showActions: true,
  config: () => ({})
})

// Emits定义
const emit = defineEmits<{
  refresh: []
  drillDown: [data: any]
  export: [type: 'png' | 'excel']
  fullscreen: []
}>()

// 响应式数据
const chartContainer = ref<HTMLElement>()
const chartInstance = ref<any>(null)
const refreshing = ref(false)

// 计算属性
const contentHeight = computed(() => {
  if (typeof props.height === 'number') {
    return `${props.height}px`
  }
  return props.height
})

// 图表配置合并
const mergedConfig = computed(() => {
  const baseConfig = {
    data: props.data,
    height: typeof props.height === 'number' ? props.height : 300,
    animation: {
      appear: {
        animation: 'fade-in',
        duration: 300
      }
    },
    theme: {
      defaultColor: '#1890FF',
      colors10: [
        '#1890FF', '#52C41A', '#FAAD14', '#F5222D', '#722ED1',
        '#13C2C2', '#FA8C16', '#A0D911', '#EB2F96', '#F759AB'
      ]
    }
  }
  
  return { ...baseConfig, ...props.config }
})

// 初始化图表
const initChart = async () => {
  if (!chartContainer.value || props.loading) return
  
  try {
    // 动态导入AntV G2Plot
    const { Line, Column, Pie, Funnel, Gauge } = await import('@antv/g2plot')
    
    // 销毁旧图表实例
    if (chartInstance.value) {
      chartInstance.value.destroy()
    }
    
    let ChartClass
    switch (props.chartType) {
      case 'line':
        ChartClass = Line
        break
      case 'column':
        ChartClass = Column
        break
      case 'pie':
        ChartClass = Pie
        break
      case 'funnel':
        ChartClass = Funnel
        break
      case 'gauge':
        ChartClass = Gauge
        break
      default:
        ChartClass = Line
    }
    
    // 创建图表实例
    chartInstance.value = new ChartClass(chartContainer.value, mergedConfig.value)
    
    // 渲染图表
    chartInstance.value.render()
    
    // 绑定图表事件
    bindChartEvents()
    
  } catch (error) {
    console.error('图表初始化失败:', error)
    emit('refresh')
  }
}

// 绑定图表事件
const bindChartEvents = () => {
  if (!chartInstance.value) return
  
  // 点击事件 - 用于数据下钻
  chartInstance.value.on('element:click', (evt: any) => {
    const { data } = evt.data
    emit('drillDown', data)
  })
  
  // 双击事件 - 全屏显示
  chartInstance.value.on('element:dblclick', () => {
    emit('fullscreen')
  })
}

// 更新图表数据
const updateChart = () => {
  if (!chartInstance.value) return
  
  try {
    chartInstance.value.update({
      ...mergedConfig.value,
      data: props.data
    })
  } catch (error) {
    console.error('图表更新失败:', error)
    // 重新初始化
    initChart()
  }
}

// 刷新处理
const handleRefresh = async () => {
  refreshing.value = true
  try {
    emit('refresh')
    await nextTick()
    // 模拟刷新延迟
    setTimeout(() => {
      refreshing.value = false
    }, 500)
  } catch (error) {
    refreshing.value = false
  }
}

// 下钻处理
const handleDrillDown = () => {
  emit('drillDown', props.data)
}

// 菜单点击处理
const handleMenuClick = ({ key }: { key: string }) => {
  switch (key) {
    case 'export-png':
      exportChart('png')
      break
    case 'export-data':
      emit('export', 'excel')
      break
    case 'fullscreen':
      emit('fullscreen')
      break
  }
}

// 导出图表
const exportChart = (type: 'png' | 'svg' = 'png') => {
  if (!chartInstance.value) return
  
  try {
    if (type === 'png') {
      chartInstance.value.downloadImage(`${props.title}-图表`, 'image/png')
    }
    emit('export', 'png')
  } catch (error) {
    console.error('导出失败:', error)
  }
}

// 监听数据变化
watch(
  () => props.data,
  (newData) => {
    if (newData && newData.length > 0) {
      updateChart()
    }
  },
  { deep: true }
)

// 监听配置变化
watch(
  () => mergedConfig.value,
  () => {
    updateChart()
  },
  { deep: true }
)

// 生命周期钩子
onMounted(async () => {
  await nextTick()
  if (props.data && props.data.length > 0) {
    initChart()
  }
})

onUnmounted(() => {
  if (chartInstance.value) {
    chartInstance.value.destroy()
  }
})

// 响应式处理
const handleResize = () => {
  if (chartInstance.value) {
    chartInstance.value.forceFit()
  }
}

// 监听窗口变化
let resizeObserver: ResizeObserver | null = null

onMounted(() => {
  if (chartContainer.value && 'ResizeObserver' in window) {
    resizeObserver = new ResizeObserver(handleResize)
    resizeObserver.observe(chartContainer.value)
  }
})

onUnmounted(() => {
  if (resizeObserver) {
    resizeObserver.disconnect()
  }
})
</script>

<style scoped lang="scss">
.chart-panel {
  @include card-style;
  
  &--loading {
    min-height: 400px;
  }
  
  // 移除AntD Card默认样式
  :deep(.ant-card-head) {
    border-bottom: 1px solid $border-color-split;
    padding: 0 $card-padding;
  }
  
  :deep(.ant-card-head-title) {
    padding: $spacing-base 0;
  }
  
  :deep(.ant-card-body) {
    padding: $card-padding;
  }
}

.chart-panel__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.chart-panel__title {
  display: flex;
  align-items: center;
  gap: $spacing-sm;
  flex: 1;
}

.chart-panel__title-text {
  font-size: $font-size-base;
  font-weight: $font-weight-medium;
  color: $gray-10;
}

.chart-panel__realtime {
  :deep(.ant-badge-status-dot) {
    @include pulse-animation;
  }
  
  :deep(.ant-badge-status-text) {
    color: $success-color;
    font-size: $font-size-xs;
    font-weight: $font-weight-medium;
  }
}

.chart-panel__extra {
  flex-shrink: 0;
}

.chart-panel__content {
  position: relative;
  width: 100%;
  min-height: $chart-container-min-height;
}

.chart-panel__chart {
  width: 100%;
  height: 100%;
}

.chart-panel__empty {
  @include flex-center;
  height: 100%;
  color: $gray-6;
}

.chart-panel__error {
  @include flex-center;
  height: 100%;
}

// 响应式适配
@include respond-to(xs) {
  .chart-panel {
    :deep(.ant-card-head) {
      padding: 0 $spacing-base;
    }
    
    :deep(.ant-card-body) {
      padding: $spacing-base;
    }
  }
  
  .chart-panel__content {
    min-height: 200px;
  }
  
  .chart-panel__header {
    flex-direction: column;
    align-items: flex-start;
    gap: $spacing-sm;
  }
  
  .chart-panel__extra {
    width: 100%;
    display: flex;
    justify-content: flex-end;
  }
}

@include respond-to(sm) {
  .chart-panel__content {
    min-height: 250px;
  }
}
</style>