<template>
  <div class="dashboard-layout">
    <!-- 页面头部 -->
    <div class="dashboard-header">
      <div class="header-left">
        <h1 class="page-title">星趣数据看板</h1>
        <div class="update-info">
          <span class="update-time">最后更新: {{ updateTime }}</span>
          <a-divider type="vertical" />
          <a-badge 
            v-if="isRealtime" 
            status="processing" 
            text="实时监控"
            class="realtime-badge"
          />
          <span v-else class="scheduled-badge">T+1更新</span>
        </div>
      </div>
      
      <div class="header-right">
        <FilterPanel 
          v-model:filters="filters"
          :loading="loading"
          @change="handleFilterChange"
          @export="handleExport"
          @reset="handleReset"
        />
      </div>
    </div>

    <!-- Tab切换 -->
    <div class="dashboard-tabs">
      <a-tabs 
        v-model:activeKey="activeTab" 
        size="large"
        @change="handleTabChange"
      >
        <a-tab-pane key="operations" tab="运营策略看板">
          <div class="tab-content">
            <OperationsDashboard
              :filters="filters"
              :loading="operationsLoading"
              @refresh="refreshOperationsData"
            />
          </div>
        </a-tab-pane>
        
        <a-tab-pane key="revenue" tab="商业化看板">
          <div class="tab-content">
            <RevenueDashboard
              :filters="filters"
              :loading="revenueLoading"
              :realtime-data="realtimeData"
              @refresh="refreshRevenueData"
            />
            
            <!-- 实时监控指示器 -->
            <div class="realtime-indicator">
              <a-badge status="processing" />
              <span class="indicator-text">实时监控中</span>
              <span class="indicator-count">{{ connectionCount }}个连接</span>
            </div>
          </div>
        </a-tab-pane>
      </a-tabs>
    </div>

    <!-- 全屏模式遮罩 -->
    <a-modal
      v-model:visible="fullscreenVisible"
      :width="'90vw'"
      :style="{ top: '20px' }"
      :footer="null"
      :mask-closable="true"
      wrap-class-name="fullscreen-modal"
    >
      <template #title>
        <div class="fullscreen-header">
          <span>{{ fullscreenTitle }}</span>
          <a-space>
            <a-button @click="exportFullscreenChart">导出图片</a-button>
            <a-button @click="fullscreenVisible = false">关闭</a-button>
          </a-space>
        </div>
      </template>
      
      <div class="fullscreen-content" v-if="fullscreenComponent">
        <component :is="fullscreenComponent" v-bind="fullscreenProps" />
      </div>
    </a-modal>

    <!-- 加载遮罩 -->
    <div v-if="globalLoading" class="loading-overlay">
      <a-spin size="large" tip="数据加载中...">
        <div class="loading-content"></div>
      </a-spin>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, provide } from 'vue'
import { message } from 'ant-design-vue'
import dayjs from 'dayjs'
import FilterPanel from '../components/FilterPanel.vue'
import OperationsDashboard from './OperationsDashboard.vue'
import RevenueDashboard from './RevenueDashboard.vue'
import { useRealtimeData } from '../composables/useRealtimeData'
import { useDashboardStore } from '../stores/dashboard'
import type { FilterOptions, RealtimeData, DashboardTab } from '../types/dashboard'

// 初始化Store
const dashboardStore = useDashboardStore()

// 响应式数据
const activeTab = ref<DashboardTab>('operations')
const filters = ref<FilterOptions>({
  dateRange: [dayjs().subtract(7, 'day'), dayjs()],
  department: '',
  channel: '',
  userSegment: '',
  granularity: 'day'
})

const operationsLoading = ref(false)
const revenueLoading = ref(false)
const globalLoading = ref(false)
const updateTime = ref('')

// 全屏模式
const fullscreenVisible = ref(false)
const fullscreenTitle = ref('')
const fullscreenComponent = ref<any>(null)
const fullscreenProps = ref<any>({})

// 实时数据
const { 
  data: realtimeData, 
  isConnected, 
  connectionCount,
  connect: connectRealtime,
  disconnect: disconnectRealtime
} = useRealtimeData()

// 计算属性
const loading = computed(() => operationsLoading.value || revenueLoading.value)
const isRealtime = computed(() => activeTab.value === 'revenue' && isConnected.value)

// 更新时间显示
const updateUpdateTime = () => {
  updateTime.value = dayjs().format('YYYY-MM-DD HH:mm:ss')
}

// Tab切换处理
const handleTabChange = (key: string) => {
  activeTab.value = key as DashboardTab
  
  // 切换到商业化看板时启动实时连接
  if (key === 'revenue') {
    connectRealtime()
  } else {
    disconnectRealtime()
  }
  
  // 更新Store状态
  dashboardStore.setActiveTab(key as DashboardTab)
}

// 筛选条件变化处理
const handleFilterChange = (newFilters: FilterOptions) => {
  filters.value = { ...newFilters }
  
  // 更新Store
  dashboardStore.setFilters(newFilters)
  
  // 刷新对应数据
  if (activeTab.value === 'operations') {
    refreshOperationsData()
  } else {
    refreshRevenueData()
  }
}

// 重置筛选条件
const handleReset = () => {
  filters.value = {
    dateRange: [dayjs().subtract(7, 'day'), dayjs()],
    department: '',
    channel: '',
    userSegment: '',
    granularity: 'day'
  }
  
  dashboardStore.resetFilters()
  
  // 刷新数据
  refreshCurrentData()
}

// 刷新当前Tab数据
const refreshCurrentData = () => {
  if (activeTab.value === 'operations') {
    refreshOperationsData()
  } else {
    refreshRevenueData()
  }
}

// 刷新运营数据
const refreshOperationsData = async () => {
  operationsLoading.value = true
  try {
    await dashboardStore.fetchOperationsData(filters.value)
    updateUpdateTime()
    message.success('运营数据已更新')
  } catch (error) {
    console.error('运营数据刷新失败:', error)
    message.error('运营数据更新失败')
  } finally {
    operationsLoading.value = false
  }
}

// 刷新商业化数据
const refreshRevenueData = async () => {
  revenueLoading.value = true
  try {
    await dashboardStore.fetchRevenueData(filters.value)
    updateUpdateTime()
    message.success('商业化数据已更新')
  } catch (error) {
    console.error('商业化数据刷新失败:', error)
    message.error('商业化数据更新失败')
  } finally {
    revenueLoading.value = false
  }
}

// 导出处理
const handleExport = async (type: 'excel' | 'pdf' = 'excel') => {
  try {
    globalLoading.value = true
    
    // 根据当前Tab导出不同数据
    const exportData = activeTab.value === 'operations' 
      ? dashboardStore.operationsData 
      : dashboardStore.revenueData
    
    // 这里实现实际的导出逻辑
    await new Promise(resolve => setTimeout(resolve, 2000)) // 模拟导出
    
    message.success(`${type.toUpperCase()}导出成功`)
  } catch (error) {
    console.error('导出失败:', error)
    message.error('导出失败')
  } finally {
    globalLoading.value = false
  }
}

// 全屏显示图表
const showFullscreen = (title: string, component: any, props: any = {}) => {
  fullscreenTitle.value = title
  fullscreenComponent.value = component
  fullscreenProps.value = props
  fullscreenVisible.value = true
}

// 导出全屏图表
const exportFullscreenChart = () => {
  // 实现全屏图表导出
  message.success('图表导出成功')
}

// 提供给子组件的方法
provide('showFullscreen', showFullscreen)
provide('refreshData', refreshCurrentData)

// 自动刷新定时器
let refreshTimer: NodeJS.Timeout | null = null

const startAutoRefresh = () => {
  // 运营数据每小时刷新一次
  if (activeTab.value === 'operations') {
    refreshTimer = setInterval(refreshOperationsData, 60 * 60 * 1000)
  }
}

const stopAutoRefresh = () => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

// 生命周期
onMounted(async () => {
  globalLoading.value = true
  
  try {
    // 初始化数据
    updateUpdateTime()
    
    // 加载初始数据
    await refreshOperationsData()
    
    // 启动自动刷新
    startAutoRefresh()
    
  } catch (error) {
    console.error('看板初始化失败:', error)
    message.error('看板初始化失败')
  } finally {
    globalLoading.value = false
  }
})

onUnmounted(() => {
  // 清理资源
  stopAutoRefresh()
  disconnectRealtime()
})

// 监听Tab变化，调整自动刷新策略
import { watch } from 'vue'

watch(activeTab, (newTab) => {
  stopAutoRefresh()
  
  if (newTab === 'operations') {
    startAutoRefresh()
  }
})
</script>

<style scoped lang="scss">
.dashboard-layout {
  min-height: 100vh;
  background: $gray-2;
  padding: $spacing-lg;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: $spacing-lg;
  background: $gray-1;
  padding: $spacing-lg;
  border-radius: $border-radius-base;
  box-shadow: $box-shadow-card;
}

.header-left {
  flex: 1;
}

.page-title {
  font-size: $font-size-xxl;
  font-weight: $font-weight-semibold;
  color: $gray-10;
  margin: 0 0 $spacing-sm 0;
}

.update-info {
  display: flex;
  align-items: center;
  font-size: $font-size-sm;
  color: $gray-7;
  
  .update-time {
    @include number-font;
  }
}

.realtime-badge {
  :deep(.ant-badge-status-dot) {
    @include pulse-animation;
  }
  
  :deep(.ant-badge-status-text) {
    color: $success-color;
    font-weight: $font-weight-medium;
  }
}

.scheduled-badge {
  color: $gray-7;
  font-size: $font-size-xs;
}

.header-right {
  flex-shrink: 0;
}

.dashboard-tabs {
  background: $gray-1;
  border-radius: $border-radius-base;
  box-shadow: $box-shadow-card;
  
  :deep(.ant-tabs-nav) {
    padding: 0 $spacing-lg;
    margin: 0;
  }
  
  :deep(.ant-tabs-tab) {
    font-size: $font-size-base;
    font-weight: $font-weight-medium;
  }
  
  :deep(.ant-tabs-content) {
    padding: 0;
  }
}

.tab-content {
  position: relative;
  padding: $spacing-lg;
}

.realtime-indicator {
  position: absolute;
  top: $spacing-base;
  right: $spacing-lg;
  display: flex;
  align-items: center;
  gap: $spacing-xs;
  font-size: $font-size-xs;
  color: $success-color;
  background: rgba(82, 196, 26, 0.1);
  padding: $spacing-xs $spacing-sm;
  border-radius: $border-radius-base;
  
  .indicator-text {
    font-weight: $font-weight-medium;
  }
  
  .indicator-count {
    color: $gray-7;
  }
}

.fullscreen-modal {
  :deep(.ant-modal) {
    max-width: none;
  }
  
  :deep(.ant-modal-body) {
    padding: 0;
    height: 70vh;
    overflow: hidden;
  }
}

.fullscreen-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.fullscreen-content {
  height: 100%;
  padding: $spacing-lg;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(4px);
  z-index: 9999;
  @include flex-center;
  
  .loading-content {
    width: 200px;
    height: 100px;
  }
}

// 响应式适配
@include respond-to(xs) {
  .dashboard-layout {
    padding: $spacing-base;
  }
  
  .dashboard-header {
    flex-direction: column;
    gap: $spacing-base;
    padding: $spacing-base;
    
    .header-right {
      width: 100%;
    }
  }
  
  .page-title {
    font-size: $font-size-xl;
  }
  
  .update-info {
    flex-wrap: wrap;
    gap: $spacing-xs;
  }
  
  .dashboard-tabs {
    :deep(.ant-tabs-nav) {
      padding: 0 $spacing-base;
    }
  }
  
  .tab-content {
    padding: $spacing-base;
  }
  
  .realtime-indicator {
    position: static;
    margin-bottom: $spacing-base;
    justify-content: center;
  }
}

@include respond-to(sm) {
  .dashboard-header {
    .header-right {
      min-width: 300px;
    }
  }
}
</style>