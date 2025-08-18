<template>
  <div ref="chartContainer" class="funnel-chart"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Funnel } from '@antv/g2plot'
import { useChartTheme } from '../../composables/useChartTheme'
import type { FunnelData } from '../../types/dashboard'

// Props定义
interface Props {
  data: FunnelData[]
  height?: number
  compareField?: string
  conversionTag?: boolean
  loading?: boolean
  maxWidth?: number
  minWidth?: number
}

const props = withDefaults(defineProps<Props>(), {
  height: 300,
  conversionTag: true,
  loading: false,
  maxWidth: 200,
  minWidth: 60
})

// Emits定义
const emit = defineEmits<{
  ready: [chart: Funnel]
  click: [data: FunnelData, event: any]
  hover: [data: FunnelData, event: any]
}>()

// 组件引用
const chartContainer = ref<HTMLElement>()
const chartInstance = ref<Funnel | null>(null)

// 使用图表主题
const { getAARRRColor, formatNumber, formatPercent } = useChartTheme()

// 创建图表实例
const createChart = async () => {
  if (!chartContainer.value || props.loading) return

  try {
    // 销毁旧实例
    if (chartInstance.value) {
      chartInstance.value.destroy()
    }

    // 处理数据，添加转化率计算
    const processedData = props.data.map((item, index) => {
      let conversion = 100
      if (index > 0) {
        const prevValue = props.data[index - 1].value
        conversion = prevValue > 0 ? (item.value / prevValue) * 100 : 0
      }
      
      return {
        ...item,
        conversion: conversion
      }
    })

    // 图表配置
    const config = {
      data: processedData,
      height: props.height,
      xField: 'stage',
      yField: 'value',
      
      // 动态配色（AARRR模型专用）
      color: (data: FunnelData) => {
        return data.color || getAARRRColor(data.stage)
      },
      
      // 漏斗样式
      funnelStyle: {
        stroke: '#fff',
        lineWidth: 2,
        fillOpacity: 0.85
      },
      
      // 最大最小宽度
      maxSize: props.maxWidth,
      minSize: props.minWidth,
      
      // 标签配置
      label: {
        content: (data: FunnelData & { conversion: number }) => {
          const lines = [
            `${data.stageName || data.stage}`,
            `${formatNumber(data.value)}`,
            `${formatPercent(data.rate / 100)}`
          ]
          return lines
        },
        style: {
          fontSize: 12,
          fill: '#fff',
          fontWeight: 500,
          textAlign: 'center',
          textBaseline: 'middle',
          fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto'
        },
        layout: 'fixed'
      },
      
      // 转化率标签
      conversionTag: props.conversionTag ? {
        visible: true,
        formatter: (meta: any) => {
          if (meta.$$index$$ === 0) return ''
          const conversion = meta.conversion || 0
          return `${conversion.toFixed(1)}%`
        },
        style: {
          fontSize: 11,
          fill: '#8C8C8C',
          fontWeight: 400
        }
      } : false,
      
      // 图例配置
      legend: {
        position: 'bottom' as const,
        layout: 'horizontal' as const,
        itemSpacing: 20,
        marker: {
          symbol: 'square',
          style: {
            r: 6
          }
        },
        text: {
          style: {
            fontSize: 12,
            fill: '#595959'
          },
          formatter: (text: string) => {
            const item = props.data.find(d => d.stage === text)
            return item?.stageName || text
          }
        }
      },
      
      // 提示框配置
      tooltip: {
        customContent: (title: string, items: any[]) => {
          if (!items || items.length === 0) return ''
          
          const item = items[0]
          const data = item.data as FunnelData & { conversion: number }
          
          return `
            <div class="custom-funnel-tooltip">
              <div class="tooltip-title">${data.stageName || data.stage}</div>
              <div class="tooltip-content">
                <div class="tooltip-row">
                  <span class="tooltip-label">用户数量:</span>
                  <span class="tooltip-value">${formatNumber(data.value)}</span>
                </div>
                <div class="tooltip-row">
                  <span class="tooltip-label">占比:</span>
                  <span class="tooltip-value">${formatPercent(data.rate / 100)}</span>
                </div>
                ${data.conversion < 100 ? `
                <div class="tooltip-row">
                  <span class="tooltip-label">转化率:</span>
                  <span class="tooltip-value">${data.conversion.toFixed(1)}%</span>
                </div>` : ''}
              </div>
            </div>`
        }
      },
      
      // 动画配置
      animation: {
        appear: {
          animation: 'grow-in-y',
          duration: 1200,
          easing: 'easeOutQuart'
        },
        update: {
          animation: 'fade-in',
          duration: 500
        }
      },
      
      // 交互配置
      interactions: [
        { type: 'element-active' },
        { type: 'element-highlight' }
      ],
      
      // 内边距
      padding: [20, 40, 60, 40] as [number, number, number, number]
    }

    // 创建图表实例
    chartInstance.value = new Funnel(chartContainer.value, config)
    
    // 绑定事件
    chartInstance.value.on('element:click', (evt: any) => {
      emit('click', evt.data.data, evt)
    })
    
    chartInstance.value.on('element:mouseover', (evt: any) => {
      emit('hover', evt.data.data, evt)
    })
    
    // 渲染图表
    chartInstance.value.render()
    
    // 通知图表就绪
    emit('ready', chartInstance.value)
    
  } catch (error) {
    console.error('FunnelChart 创建失败:', error)
  }
}

// 更新图表数据
const updateChart = () => {
  if (!chartInstance.value) return
  
  try {
    // 重新处理数据
    const processedData = props.data.map((item, index) => {
      let conversion = 100
      if (index > 0) {
        const prevValue = props.data[index - 1].value
        conversion = prevValue > 0 ? (item.value / prevValue) * 100 : 0
      }
      
      return {
        ...item,
        conversion: conversion
      }
    })
    
    chartInstance.value.update({
      data: processedData
    })
  } catch (error) {
    console.error('FunnelChart 更新失败:', error)
    // 重新创建图表
    createChart()
  }
}

// 销毁图表
const destroyChart = () => {
  if (chartInstance.value) {
    chartInstance.value.destroy()
    chartInstance.value = null
  }
}

// 监听数据变化
watch(
  () => props.data,
  (newData) => {
    if (newData && newData.length > 0) {
      if (chartInstance.value) {
        updateChart()
      } else {
        createChart()
      }
    }
  },
  { deep: true }
)

// 监听其他配置变化
watch(
  () => [props.height, props.conversionTag, props.maxWidth, props.minWidth],
  () => {
    if (chartInstance.value) {
      destroyChart()
      nextTick(() => {
        createChart()
      })
    }
  }
)

// 生命周期
onMounted(async () => {
  await nextTick()
  if (props.data && props.data.length > 0) {
    createChart()
  }
})

onUnmounted(() => {
  destroyChart()
})

// 暴露方法
defineExpose({
  chart: chartInstance,
  refresh: createChart,
  destroy: destroyChart
})
</script>

<style scoped lang="scss">
.funnel-chart {
  width: 100%;
  height: 100%;
}

// 自定义漏斗图Tooltip样式
:global(.custom-funnel-tooltip) {
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid #F0F0F0;
  border-radius: 6px;
  padding: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(8px);
  min-width: 160px;
  
  .tooltip-title {
    font-size: 13px;
    font-weight: 500;
    color: #262626;
    margin-bottom: 8px;
    padding-bottom: 4px;
    border-bottom: 1px solid #F0F0F0;
  }
  
  .tooltip-content {
    .tooltip-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 4px;
      font-size: 12px;
      
      &:last-child {
        margin-bottom: 0;
      }
    }
    
    .tooltip-label {
      color: #595959;
    }
    
    .tooltip-value {
      font-family: 'SF Mono', Monaco, 'Roboto Mono', monospace;
      font-weight: 500;
      color: #262626;
    }
  }
}

// 漏斗图转化率标签样式调整
:global(.g2-element-label) {
  .conversion-tag {
    font-size: 11px;
    fill: #8C8C8C;
    text-anchor: middle;
  }
}
</style>