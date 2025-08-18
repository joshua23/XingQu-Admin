<template>
  <div ref="chartContainer" class="gauge-chart"></div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Gauge } from '@antv/g2plot'
import { useChartTheme } from '../../composables/useChartTheme'
import type { GaugeData } from '../../types/dashboard'

// Props定义
interface Props {
  data: GaugeData
  height?: number
  innerRadius?: number
  outerRadius?: number
  startAngle?: number
  endAngle?: number
  showIndicator?: boolean
  showAxis?: boolean
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  height: 200,
  innerRadius: 0.75,
  outerRadius: 0.95,
  startAngle: (-7 * Math.PI) / 6,
  endAngle: (Math.PI) / 6,
  showIndicator: true,
  showAxis: true,
  loading: false
})

// Emits定义
const emit = defineEmits<{
  ready: [chart: Gauge]
  change: [percent: number, value: number]
}>()

// 组件引用
const chartContainer = ref<HTMLElement>()
const chartInstance = ref<Gauge | null>(null)

// 使用图表主题
const { colors, formatNumber, formatCurrency } = useChartTheme()

// 计算百分比
const percent = computed(() => {
  if (props.data.target <= 0) return 0
  return Math.min(props.data.current / props.data.target, 1)
})

// 获取状态颜色
const getStatusColor = (percent: number) => {
  if (percent < 0.3) return colors.error    // 红色：0-30%
  if (percent < 0.6) return colors.warning  // 黄色：30-60%
  if (percent < 0.8) return colors.info     // 蓝色：60-80%
  return colors.success                     // 绿色：80-100%
}

// 创建图表实例
const createChart = async () => {
  if (!chartContainer.value || props.loading) return

  try {
    // 销毁旧实例
    if (chartInstance.value) {
      chartInstance.value.destroy()
    }

    const currentPercent = percent.value
    const statusColor = getStatusColor(currentPercent)

    // 图表配置
    const config = {
      percent: currentPercent,
      height: props.height,
      
      // 仪表盘范围配置
      range: {
        ticks: [0, 1/3, 2/3, 1],
        color: [colors.error, colors.warning, colors.info, colors.success]
      },
      
      // 仪表盘半径
      innerRadius: props.innerRadius,
      outerRadius: props.outerRadius,
      
      // 角度范围
      startAngle: props.startAngle,
      endAngle: props.endAngle,
      
      // 指示器配置
      indicator: props.showIndicator ? {
        pointer: {
          style: {
            stroke: statusColor,
            lineWidth: 3,
            fill: statusColor
          }
        },
        pin: {
          style: {
            r: 6,
            stroke: statusColor,
            fill: statusColor
          }
        }
      } : false,
      
      // 刻度配置
      axis: props.showAxis ? {
        label: {
          formatter: (v: string) => {
            const value = Number(v)
            if (value === 0) return '0%'
            if (value === 1/3) return '33%'
            if (value === 2/3) return '67%'
            if (value === 1) return '100%'
            return `${(value * 100).toFixed(0)}%`
          },
          style: {
            fontSize: 10,
            fill: '#8C8C8C',
            textAlign: 'center'
          }
        },
        tickLine: {
          style: {
            stroke: '#D9D9D9',
            lineWidth: 1
          }
        },
        subTickLine: {
          count: 3,
          style: {
            stroke: '#D9D9D9',
            lineWidth: 1,
            lineDash: [2, 2]
          }
        }
      } : false,
      
      // 统计文本（中心显示）
      statistic: {
        title: {
          content: props.data.title,
          style: {
            fontSize: 12,
            color: '#8C8C8C',
            fontWeight: 400
          }
        },
        content: {
          content: `${(currentPercent * 100).toFixed(1)}%`,
          style: {
            fontSize: 24,
            fontWeight: 600,
            color: statusColor,
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto'
          }
        }
      },
      
      // 仪表盘样式
      gaugeStyle: {
        lineCap: 'round',
        lineWidth: 8
      },
      
      // 动画配置
      animation: {
        appear: {
          animation: 'grow-in-xy',
          duration: 1000,
          easing: 'easeOutQuart'
        },
        update: {
          animation: 'fade-in',
          duration: 800,
          easing: 'easeOutQuart'
        }
      }
    }

    // 创建图表实例
    chartInstance.value = new Gauge(chartContainer.value, config)
    
    // 渲染图表
    chartInstance.value.render()
    
    // 通知图表就绪
    emit('ready', chartInstance.value)
    
    // 监听数据变化
    emit('change', currentPercent, props.data.current)
    
  } catch (error) {
    console.error('GaugeChart 创建失败:', error)
  }
}

// 更新图表数据
const updateChart = () => {
  if (!chartInstance.value) return
  
  try {
    const currentPercent = percent.value
    const statusColor = getStatusColor(currentPercent)
    
    // 更新百分比
    chartInstance.value.update({
      percent: currentPercent
    })
    
    // 更新统计文本
    chartInstance.value.update({
      statistic: {
        title: {
          content: props.data.title,
          style: {
            fontSize: 12,
            color: '#8C8C8C',
            fontWeight: 400
          }
        },
        content: {
          content: `${(currentPercent * 100).toFixed(1)}%`,
          style: {
            fontSize: 24,
            fontWeight: 600,
            color: statusColor
          }
        }
      }
    })
    
    // 更新指示器颜色
    chartInstance.value.update({
      indicator: {
        pointer: {
          style: {
            stroke: statusColor,
            fill: statusColor
          }
        },
        pin: {
          style: {
            stroke: statusColor,
            fill: statusColor
          }
        }
      }
    })
    
    // 触发变化事件
    emit('change', currentPercent, props.data.current)
    
  } catch (error) {
    console.error('GaugeChart 更新失败:', error)
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
    if (newData) {
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
  () => [
    props.height, 
    props.innerRadius, 
    props.outerRadius, 
    props.startAngle, 
    props.endAngle,
    props.showIndicator,
    props.showAxis
  ],
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
  if (props.data) {
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
  destroy: destroyChart,
  percent: percent
})
</script>

<style scoped lang="scss">
.gauge-chart {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

// 仪表盘附加信息样式
.gauge-info {
  position: absolute;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  text-align: center;
  
  .gauge-current {
    font-size: 14px;
    font-weight: 500;
    color: #262626;
    font-family: 'SF Mono', Monaco, 'Roboto Mono', monospace;
  }
  
  .gauge-target {
    font-size: 12px;
    color: #8C8C8C;
    margin-top: 2px;
  }
}
</style>