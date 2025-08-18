<template>
  <div ref="chartContainer" class="line-chart"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Line } from '@antv/g2plot'
import { useChartTheme } from '../../composables/useChartTheme'
import type { ChartDataPoint } from '../../types/dashboard'

// Props定义
interface Props {
  data: ChartDataPoint[]
  xField: string
  yField: string
  seriesField?: string
  title?: string
  height?: number
  smooth?: boolean
  point?: boolean
  area?: boolean
  color?: string | string[]
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  height: 300,
  smooth: true,
  point: true,
  area: false,
  loading: false
})

// Emits定义
const emit = defineEmits<{
  ready: [chart: Line]
  click: [data: any, event: any]
  hover: [data: any, event: any]
}>()

// 组件引用
const chartContainer = ref<HTMLElement>()
const chartInstance = ref<Line | null>(null)

// 使用图表主题
const { economistTheme, formatNumber, colors } = useChartTheme()

// 创建图表实例
const createChart = async () => {
  if (!chartContainer.value || props.loading) return

  try {
    // 销毁旧实例
    if (chartInstance.value) {
      chartInstance.value.destroy()
    }

    // 图表配置
    const config = {
      data: props.data,
      height: props.height,
      xField: props.xField,
      yField: props.yField,
      seriesField: props.seriesField,
      
      // 样式配置
      smooth: props.smooth,
      color: props.color || (props.seriesField ? economistTheme.colors10 : colors.primary),
      
      // 线条样式
      lineStyle: {
        lineWidth: 2,
        lineCap: 'round',
        lineJoin: 'round'
      },
      
      // 点样式
      point: props.point ? {
        size: 3,
        shape: 'circle',
        style: {
          fill: 'white',
          stroke: colors.primary,
          lineWidth: 2
        }
      } : false,
      
      // 区域填充
      area: props.area ? {
        style: {
          fillOpacity: 0.2
        }
      } : undefined,
      
      // X轴配置
      xAxis: {
        type: 'time',
        mask: 'MM-DD',
        tickCount: 7,
        label: {
          style: economistTheme.axis?.common?.label?.style,
          formatter: (text: string) => {
            // 根据数据类型格式化X轴标签
            const date = new Date(text)
            if (!isNaN(date.getTime())) {
              return date.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
            }
            return text
          }
        },
        line: economistTheme.axis?.common?.line,
        tickLine: economistTheme.axis?.common?.tickLine,
        grid: null // 经济学人风格不显示垂直网格线
      },
      
      // Y轴配置
      yAxis: {
        label: {
          style: economistTheme.axis?.common?.label?.style,
          formatter: (value: string) => formatNumber(Number(value))
        },
        line: null, // 经济学人风格不显示Y轴线
        tickLine: null,
        grid: economistTheme.axis?.common?.grid
      },
      
      // 图例配置
      legend: props.seriesField ? {
        position: 'top' as const,
        marker: economistTheme.legend?.common?.marker,
        text: economistTheme.legend?.common?.text
      } : false,
      
      // 提示框配置
      tooltip: {
        shared: true,
        showCrosshairs: true,
        crosshairs: {
          type: 'x',
          line: {
            style: {
              stroke: colors.primary,
              lineWidth: 1,
              lineDash: [4, 4]
            }
          }
        },
        customContent: (title: string, items: any[]) => {
          if (!items || items.length === 0) return ''
          
          let content = `<div class="custom-tooltip">
            <div class="tooltip-title">${title}</div>`
          
          items.forEach((item) => {
            const { name, value, color } = item
            content += `
              <div class="tooltip-item">
                <span class="tooltip-marker" style="background-color: ${color}"></span>
                <span class="tooltip-name">${name || props.yField}:</span>
                <span class="tooltip-value">${formatNumber(value)}</span>
              </div>`
          })
          
          content += '</div>'
          return content
        }
      },
      
      // 动画配置
      animation: {
        appear: {
          animation: 'path-in',
          duration: 1000,
          easing: 'easeOutQuart'
        },
        update: {
          animation: 'fade-in',
          duration: 500,
          easing: 'easeOutQuart'
        }
      },
      
      // 交互配置
      interactions: [
        { type: 'marker-active' },
        { type: 'brush' }
      ],
      
      // 主题应用
      theme: economistTheme,
      
      // 内边距
      padding: [20, 20, 40, 40] as [number, number, number, number]
    }

    // 创建图表实例
    chartInstance.value = new Line(chartContainer.value, config)
    
    // 绑定事件
    chartInstance.value.on('plot:click', (evt: any) => {
      emit('click', evt.data, evt)
    })
    
    chartInstance.value.on('element:mouseover', (evt: any) => {
      emit('hover', evt.data, evt)
    })
    
    // 渲染图表
    chartInstance.value.render()
    
    // 通知图表就绪
    emit('ready', chartInstance.value)
    
  } catch (error) {
    console.error('LineChart 创建失败:', error)
  }
}

// 更新图表数据
const updateChart = () => {
  if (!chartInstance.value) return
  
  try {
    chartInstance.value.update({
      data: props.data
    })
  } catch (error) {
    console.error('LineChart 更新失败:', error)
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
  () => [props.height, props.smooth, props.point, props.area, props.color],
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
.line-chart {
  width: 100%;
  height: 100%;
}

// 自定义Tooltip样式
:global(.custom-tooltip) {
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid #F0F0F0;
  border-radius: 6px;
  padding: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(8px);
  
  .tooltip-title {
    font-size: 13px;
    font-weight: 500;
    color: #262626;
    margin-bottom: 8px;
    padding-bottom: 4px;
    border-bottom: 1px solid #F0F0F0;
  }
  
  .tooltip-item {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 4px;
    font-size: 12px;
    
    &:last-child {
      margin-bottom: 0;
    }
  }
  
  .tooltip-marker {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }
  
  .tooltip-name {
    color: #595959;
    min-width: 60px;
  }
  
  .tooltip-value {
    font-family: 'SF Mono', Monaco, 'Roboto Mono', monospace;
    font-weight: 500;
    color: #262626;
  }
}
</style>