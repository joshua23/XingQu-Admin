<template>
  <a-card 
    class="metric-card" 
    :class="[
      `metric-card--${size}`,
      { 'metric-card--loading': loading }
    ]"
    :hoverable="!loading"
    :loading="loading"
  >
    <div class="metric-card__content">
      <!-- 图标区域 -->
      <div class="metric-card__icon" v-if="data.icon">
        <component :is="iconComponent" />
      </div>
      
      <!-- 指标内容 -->
      <div class="metric-card__body">
        <div class="metric-card__label">
          {{ data.label }}
          <a-tooltip v-if="data.description" :title="data.description">
            <InfoCircleOutlined class="metric-card__info" />
          </a-tooltip>
        </div>
        
        <div class="metric-card__value">
          <span v-if="data.prefix" class="metric-card__prefix">{{ data.prefix }}</span>
          <span class="metric-card__number">{{ formattedValue }}</span>
          <span v-if="data.suffix" class="metric-card__suffix">{{ data.suffix }}</span>
        </div>
        
        <div 
          v-if="data.change !== undefined" 
          class="metric-card__change"
          :class="changeClass"
        >
          <component :is="changeIcon" class="metric-card__change-icon" />
          <span class="metric-card__change-text">{{ changeText }}</span>
        </div>
      </div>
    </div>
    
    <!-- 点击波纹效果 -->
    <div class="metric-card__ripple" v-if="!loading" @click="handleClick"></div>
  </a-card>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { Component } from 'vue'
import { 
  InfoCircleOutlined,
  CaretUpOutlined,
  CaretDownOutlined,
  MinusOutlined
} from '@ant-design/icons-vue'
import type { MetricData } from '../types/dashboard'

// Props定义
interface Props {
  data: MetricData
  loading?: boolean
  size?: 'small' | 'default' | 'large'
  clickable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  size: 'default',
  clickable: true
})

// Emits定义
const emit = defineEmits<{
  click: [data: MetricData]
  hover: [data: MetricData]
}>()

// 动态图标组件
const iconComponent = computed<Component>(() => {
  if (!props.data.icon) return 'div'
  
  // 这里可以根据icon字符串动态导入图标
  // 简化示例，实际项目中可以建立图标映射表
  const iconMap: Record<string, Component> = {
    'user': InfoCircleOutlined,
    'chart': InfoCircleOutlined,
    'money': InfoCircleOutlined,
    'time': InfoCircleOutlined
  }
  
  return iconMap[props.data.icon] || InfoCircleOutlined
})

// 格式化数值显示
const formattedValue = computed(() => {
  const value = props.data.value
  if (typeof value === 'string') return value
  
  // 数字格式化逻辑
  if (value >= 10000) {
    return (value / 10000).toFixed(1) + 'w'
  } else if (value >= 1000) {
    return (value / 1000).toFixed(1) + 'k'
  }
  
  return value.toLocaleString()
})

// 变化趋势样式类
const changeClass = computed(() => {
  if (!props.data.change) return ''
  
  switch (props.data.changeType) {
    case 'increase':
      return 'metric-card__change--positive'
    case 'decrease':
      return 'metric-card__change--negative'
    default:
      return 'metric-card__change--neutral'
  }
})

// 变化趋势图标
const changeIcon = computed<Component>(() => {
  if (!props.data.change) return MinusOutlined
  
  switch (props.data.changeType) {
    case 'increase':
      return CaretUpOutlined
    case 'decrease':
      return CaretDownOutlined
    default:
      return MinusOutlined
  }
})

// 变化趋势文本
const changeText = computed(() => {
  if (!props.data.change) return ''
  
  const change = Math.abs(props.data.change)
  const symbol = props.data.changeType === 'increase' ? '+' : 
                 props.data.changeType === 'decrease' ? '' : '±'
  
  // 判断是百分比还是数值
  const isPercentage = change < 1 && change > -1 && change !== 0
  
  if (isPercentage) {
    return `${symbol}${(change * 100).toFixed(1)}%`
  } else {
    return `${symbol}${change.toFixed(1)}%`
  }
})

// 点击处理
const handleClick = () => {
  if (props.loading || !props.clickable) return
  
  emit('click', props.data)
  
  // 添加点击波纹效果
  addRippleEffect()
}

// 波纹效果
const addRippleEffect = () => {
  // 简化的波纹效果实现
  console.log('添加波纹效果')
}
</script>

<style scoped lang="scss">
.metric-card {
  @include card-style;
  position: relative;
  cursor: pointer;
  transition: all $transition-duration-base $ease-out;
  
  &:hover:not(.metric-card--loading) {
    transform: translateY(-2px);
    box-shadow: $box-shadow-card-hover;
  }
  
  // 尺寸变体
  &--small {
    .metric-card__content {
      padding: $spacing-base;
    }
    
    .metric-card__value {
      font-size: $font-size-xl;
    }
  }
  
  &--large {
    .metric-card__content {
      padding: $spacing-xl;
    }
    
    .metric-card__value {
      font-size: 40px;
    }
  }
  
  &--loading {
    cursor: default;
    
    &:hover {
      transform: none;
      box-shadow: $box-shadow-card;
    }
  }
  
  // 移除AntD Card默认样式
  :deep(.ant-card-body) {
    padding: 0;
  }
}

.metric-card__content {
  display: flex;
  align-items: flex-start;
  gap: $spacing-base;
  padding: $card-padding;
}

.metric-card__icon {
  font-size: 20px;
  color: $gray-7;
  margin-top: 4px;
  flex-shrink: 0;
}

.metric-card__body {
  flex: 1;
  min-width: 0;
}

.metric-card__label {
  display: flex;
  align-items: center;
  gap: $spacing-xs;
  font-size: $font-size-sm;
  color: $gray-7;
  margin-bottom: $spacing-sm;
  line-height: $line-height-base;
}

.metric-card__info {
  font-size: 12px;
  color: $gray-6;
  cursor: help;
  
  &:hover {
    color: $primary-color;
  }
}

.metric-card__value {
  display: flex;
  align-items: baseline;
  gap: 2px;
  margin-bottom: $spacing-sm;
  line-height: 1.2;
}

.metric-card__prefix,
.metric-card__suffix {
  font-size: $font-size-lg;
  color: $gray-8;
  font-weight: $font-weight-normal;
}

.metric-card__number {
  @include number-font;
  font-size: $font-size-xxxl;
  font-weight: $font-weight-semibold;
  color: $metric-value-color;
}

.metric-card__change {
  display: flex;
  align-items: center;
  gap: $spacing-xs;
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  
  &--positive {
    color: $metric-positive;
  }
  
  &--negative {
    color: $metric-negative;
  }
  
  &--neutral {
    color: $metric-neutral;
  }
}

.metric-card__change-icon {
  font-size: 12px;
}

.metric-card__change-text {
  @include number-font;
}

.metric-card__ripple {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  border-radius: $border-radius-base;
  overflow: hidden;
}

// 响应式适配
@include respond-to(xs) {
  .metric-card {
    .metric-card__content {
      padding: $spacing-base;
    }
    
    .metric-card__value {
      .metric-card__number {
        font-size: $font-size-xl;
      }
    }
    
    .metric-card__change {
      font-size: $font-size-xs;
    }
  }
}

@include respond-to(sm) {
  .metric-card {
    .metric-card__value {
      .metric-card__number {
        font-size: 28px;
      }
    }
  }
}
</style>