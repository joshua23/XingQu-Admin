<template>
  <div class="filter-panel">
    <a-space :size="16" wrap class="filter-panel__controls">
      <!-- 时间选择器 -->
      <div class="filter-panel__item">
        <a-range-picker
          v-model:value="localFilters.dateRange"
          :presets="datePresets"
          :disabled="loading"
          @change="handleDateChange"
          format="YYYY-MM-DD"
          :placeholder="['开始日期', '结束日期']"
        />
      </div>
      
      <!-- 部门筛选 -->
      <div class="filter-panel__item" v-if="showDepartment">
        <a-select
          v-model:value="localFilters.department"
          :placeholder="departmentPlaceholder"
          :disabled="loading"
          :loading="loadingDepartments"
          style="width: 120px"
          @change="handleFilterChange"
          allow-clear
        >
          <a-select-option value="">全部部门</a-select-option>
          <a-select-option 
            v-for="dept in departments"
            :key="dept.value"
            :value="dept.value"
          >
            {{ dept.label }}
          </a-select-option>
        </a-select>
      </div>
      
      <!-- 渠道筛选 -->
      <div class="filter-panel__item" v-if="showChannel">
        <a-select
          v-model:value="localFilters.channel"
          :placeholder="channelPlaceholder"
          :disabled="loading || loadingChannels"
          :loading="loadingChannels"
          style="width: 120px"
          @change="handleFilterChange"
          allow-clear
        >
          <a-select-option value="">全部渠道</a-select-option>
          <a-select-option 
            v-for="channel in availableChannels"
            :key="channel.value"
            :value="channel.value"
          >
            {{ channel.label }}
          </a-select-option>
        </a-select>
      </div>
      
      <!-- 用户分群筛选 -->
      <div class="filter-panel__item" v-if="showUserSegment">
        <a-select
          v-model:value="localFilters.userSegment"
          :placeholder="userSegmentPlaceholder"
          :disabled="loading"
          style="width: 120px"
          @change="handleFilterChange"
          allow-clear
        >
          <a-select-option value="">全部用户</a-select-option>
          <a-select-option 
            v-for="segment in userSegments"
            :key="segment.value"
            :value="segment.value"
          >
            {{ segment.label }}
          </a-select-option>
        </a-select>
      </div>
      
      <!-- 时间粒度 -->
      <div class="filter-panel__item" v-if="showGranularity">
        <a-select
          v-model:value="localFilters.granularity"
          :disabled="loading"
          style="width: 80px"
          @change="handleFilterChange"
        >
          <a-select-option value="day">日</a-select-option>
          <a-select-option value="week">周</a-select-option>
          <a-select-option value="month">月</a-select-option>
        </a-select>
      </div>
      
      <!-- 操作按钮组 -->
      <div class="filter-panel__actions">
        <a-space size="small">
          <!-- 重置按钮 -->
          <a-tooltip title="重置筛选条件">
            <a-button 
              :disabled="loading"
              @click="handleReset"
            >
              <template #icon>
                <ClearOutlined />
              </template>
              重置
            </a-button>
          </a-tooltip>
          
          <!-- 导出按钮 -->
          <a-tooltip title="导出数据">
            <a-button 
              type="primary"
              :disabled="loading"
              :loading="exporting"
              @click="handleExport"
              v-if="showExport"
            >
              <template #icon>
                <DownloadOutlined />
              </template>
              导出
            </a-button>
          </a-tooltip>
          
          <!-- 更多操作 -->
          <a-dropdown v-if="showMoreActions">
            <a-button :disabled="loading">
              <template #icon>
                <MoreOutlined />
              </template>
            </a-button>
            <template #overlay>
              <a-menu @click="handleMenuClick">
                <a-menu-item key="export-excel">
                  <FileExcelOutlined />
                  导出Excel
                </a-menu-item>
                <a-menu-item key="export-pdf">
                  <FilePdfOutlined />
                  导出PDF
                </a-menu-item>
                <a-menu-divider />
                <a-menu-item key="save-preset">
                  <SaveOutlined />
                  保存筛选条件
                </a-menu-item>
                <a-menu-item key="load-preset">
                  <FolderOpenOutlined />
                  加载筛选条件
                </a-menu-item>
              </a-menu>
            </template>
          </a-dropdown>
        </a-space>
      </div>
    </a-space>
    
    <!-- 活跃筛选条件标签 -->
    <div v-if="activeFilters.length > 0" class="filter-panel__tags">
      <span class="filter-panel__tags-label">当前筛选:</span>
      <a-space size="small" wrap>
        <a-tag
          v-for="filter in activeFilters"
          :key="filter.key"
          :closable="!loading"
          @close="removeFilter(filter.key)"
          color="blue"
        >
          {{ filter.label }}
        </a-tag>
      </a-space>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, onMounted } from 'vue'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import {
  ClearOutlined,
  DownloadOutlined,
  MoreOutlined,
  FileExcelOutlined,
  FilePdfOutlined,
  SaveOutlined,
  FolderOpenOutlined
} from '@ant-design/icons-vue'
import type { FilterOptions } from '../types/dashboard'

// 选项数据接口
interface SelectOption {
  label: string
  value: string
}

// Props定义
interface Props {
  filters: FilterOptions
  loading?: boolean
  showDepartment?: boolean
  showChannel?: boolean
  showUserSegment?: boolean
  showGranularity?: boolean
  showExport?: boolean
  showMoreActions?: boolean
  departmentPlaceholder?: string
  channelPlaceholder?: string
  userSegmentPlaceholder?: string
  departments?: SelectOption[]
  channels?: SelectOption[]
  userSegments?: SelectOption[]
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  showDepartment: true,
  showChannel: true,
  showUserSegment: true,
  showGranularity: true,
  showExport: true,
  showMoreActions: true,
  departmentPlaceholder: '选择部门',
  channelPlaceholder: '选择渠道',
  userSegmentPlaceholder: '选择用户分群',
  departments: () => [
    { label: '运营部', value: 'ops' },
    { label: '技术部', value: 'dev' },
    { label: '商务部', value: 'business' }
  ],
  channels: () => [
    { label: '应用商店', value: 'appstore' },
    { label: '微信小程序', value: 'wechat' },
    { label: '官方网站', value: 'website' },
    { label: '推广渠道', value: 'ads' }
  ],
  userSegments: () => [
    { label: '新用户', value: 'new' },
    { label: '活跃用户', value: 'active' },
    { label: '付费用户', value: 'paid' },
    { label: '流失用户', value: 'churned' }
  ]
})

// Emits定义
const emit = defineEmits<{
  'update:filters': [filters: FilterOptions]
  'change': [filters: FilterOptions]
  'export': [type?: 'excel' | 'pdf']
  'reset': []
  'save-preset': [filters: FilterOptions]
  'load-preset': []
}>()

// 响应式数据
const exporting = ref(false)
const loadingDepartments = ref(false)
const loadingChannels = ref(false)

// 本地筛选状态
const localFilters = reactive<FilterOptions>({
  dateRange: [...props.filters.dateRange],
  department: props.filters.department,
  channel: props.filters.channel,
  userSegment: props.filters.userSegment,
  granularity: props.filters.granularity || 'day'
})

// 时间预设选项
const datePresets = [
  { 
    label: '今日', 
    value: [dayjs().startOf('day'), dayjs().endOf('day')] as [Dayjs, Dayjs]
  },
  { 
    label: '昨日', 
    value: [
      dayjs().subtract(1, 'day').startOf('day'), 
      dayjs().subtract(1, 'day').endOf('day')
    ] as [Dayjs, Dayjs]
  },
  { 
    label: '最近7天', 
    value: [dayjs().subtract(7, 'day'), dayjs()] as [Dayjs, Dayjs]
  },
  { 
    label: '最近30天', 
    value: [dayjs().subtract(30, 'day'), dayjs()] as [Dayjs, Dayjs]
  },
  { 
    label: '本月', 
    value: [dayjs().startOf('month'), dayjs().endOf('month')] as [Dayjs, Dayjs]
  },
  { 
    label: '上月', 
    value: [
      dayjs().subtract(1, 'month').startOf('month'),
      dayjs().subtract(1, 'month').endOf('month')
    ] as [Dayjs, Dayjs]
  }
]

// 可用渠道（基于部门筛选）
const availableChannels = computed(() => {
  if (!localFilters.department) {
    return props.channels
  }
  
  // 根据部门过滤渠道选项
  const departmentChannelMap: Record<string, string[]> = {
    'ops': ['appstore', 'wechat', 'ads'],
    'dev': ['website', 'appstore'],
    'business': ['ads', 'website']
  }
  
  const allowedChannels = departmentChannelMap[localFilters.department] || []
  return props.channels?.filter(channel => 
    allowedChannels.includes(channel.value)
  ) || []
})

// 活跃筛选条件
const activeFilters = computed(() => {
  const filters = []
  
  // 时间范围
  if (localFilters.dateRange[0] && localFilters.dateRange[1]) {
    const start = localFilters.dateRange[0].format('MM-DD')
    const end = localFilters.dateRange[1].format('MM-DD')
    filters.push({
      key: 'dateRange',
      label: `时间: ${start} ~ ${end}`
    })
  }
  
  // 部门
  if (localFilters.department) {
    const dept = props.departments?.find(d => d.value === localFilters.department)
    filters.push({
      key: 'department',
      label: `部门: ${dept?.label}`
    })
  }
  
  // 渠道
  if (localFilters.channel) {
    const channel = props.channels?.find(c => c.value === localFilters.channel)
    filters.push({
      key: 'channel',
      label: `渠道: ${channel?.label}`
    })
  }
  
  // 用户分群
  if (localFilters.userSegment) {
    const segment = props.userSegments?.find(s => s.value === localFilters.userSegment)
    filters.push({
      key: 'userSegment',
      label: `用户: ${segment?.label}`
    })
  }
  
  return filters
})

// 事件处理
const handleDateChange = (dates: [Dayjs, Dayjs] | null) => {
  if (dates) {
    localFilters.dateRange = dates
  }
  handleFilterChange()
}

const handleFilterChange = () => {
  // 部门变化时清空渠道选择
  if (localFilters.channel && 
      !availableChannels.value.some(c => c.value === localFilters.channel)) {
    localFilters.channel = ''
  }
  
  const updatedFilters = { ...localFilters }
  emit('update:filters', updatedFilters)
  emit('change', updatedFilters)
}

const handleReset = () => {
  localFilters.dateRange = [dayjs().subtract(7, 'day'), dayjs()]
  localFilters.department = ''
  localFilters.channel = ''
  localFilters.userSegment = ''
  localFilters.granularity = 'day'
  
  emit('reset')
  handleFilterChange()
}

const handleExport = async () => {
  exporting.value = true
  try {
    emit('export')
    // 模拟导出延迟
    await new Promise(resolve => setTimeout(resolve, 1000))
  } finally {
    exporting.value = false
  }
}

const handleMenuClick = ({ key }: { key: string }) => {
  switch (key) {
    case 'export-excel':
      emit('export', 'excel')
      break
    case 'export-pdf':
      emit('export', 'pdf')
      break
    case 'save-preset':
      emit('save-preset', { ...localFilters })
      break
    case 'load-preset':
      emit('load-preset')
      break
  }
}

const removeFilter = (filterKey: string) => {
  switch (filterKey) {
    case 'dateRange':
      localFilters.dateRange = [dayjs().subtract(7, 'day'), dayjs()]
      break
    case 'department':
      localFilters.department = ''
      break
    case 'channel':
      localFilters.channel = ''
      break
    case 'userSegment':
      localFilters.userSegment = ''
      break
  }
  handleFilterChange()
}

// 监听外部筛选变化
watch(() => props.filters, (newFilters) => {
  Object.assign(localFilters, newFilters)
}, { deep: true })

// 组件挂载时同步初始筛选条件
onMounted(() => {
  if (props.filters) {
    Object.assign(localFilters, props.filters)
  }
})
</script>

<style scoped lang="scss">
.filter-panel {
  background: $gray-1;
  border: 1px solid $border-color-base;
  border-radius: $border-radius-base;
  padding: $spacing-base $spacing-lg;
  margin-bottom: $section-margin;
}

.filter-panel__controls {
  width: 100%;
  
  .ant-space-item {
    display: flex;
  }
}

.filter-panel__item {
  display: flex;
  align-items: center;
  
  .ant-picker,
  .ant-select {
    min-width: 120px;
  }
}

.filter-panel__actions {
  margin-left: auto;
  
  @include respond-to(xs) {
    margin-left: 0;
    width: 100%;
    
    .ant-space {
      justify-content: flex-end;
    }
  }
}

.filter-panel__tags {
  display: flex;
  align-items: center;
  gap: $spacing-sm;
  margin-top: $spacing-base;
  padding-top: $spacing-base;
  border-top: 1px solid $border-color-split;
}

.filter-panel__tags-label {
  font-size: $font-size-sm;
  color: $gray-7;
  flex-shrink: 0;
}

// 响应式适配
@include respond-to(xs) {
  .filter-panel {
    padding: $spacing-base;
  }
  
  .filter-panel__controls {
    .ant-space-item {
      flex-direction: column;
      align-items: stretch;
    }
  }
  
  .filter-panel__item {
    width: 100%;
    
    .ant-picker,
    .ant-select {
      width: 100%;
      min-width: auto;
    }
  }
  
  .filter-panel__tags {
    flex-direction: column;
    align-items: flex-start;
    gap: $spacing-xs;
  }
}

@include respond-to(sm) {
  .filter-panel__controls {
    .ant-space-item {
      min-width: 120px;
    }
  }
}
</style>