import React from 'react';
import ReactDOM from 'react-dom/client';
import DashboardComponent from './DashboardComponent';
import { FeishuContext } from '@xingqu/shared/src/types';
import '@xingqu/shared/src/styles/globals.css';

// 获取飞书上下文参数
function getFeishuContext(): FeishuContext | undefined {
  const urlParams = new URLSearchParams(window.location.search);
  
  const userId = urlParams.get('feishu_user_id');
  if (!userId) return undefined;
  
  return {
    userId,
    userName: urlParams.get('feishu_user_name') || '未知用户',
    tableId: urlParams.get('feishu_table_id') || '',
    permissions: (urlParams.get('permissions') || '').split(',').filter(Boolean),
    locale: (urlParams.get('locale') as 'zh-CN' | 'en-US') || 'zh-CN',
    theme: (urlParams.get('theme') as 'light' | 'dark') || 'light'
  };
}

// 飞书消息通信
function setupFeishuMessaging() {
  // 监听来自飞书的消息
  window.addEventListener('message', (event) => {
    // 验证消息来源
    const validOrigins = [
      'https://feishu.cn',
      'https://larksuite.com', 
      'https://bytedance.feishu.cn'
    ];
    
    if (!validOrigins.some(origin => event.origin.includes(origin))) {
      return;
    }

    const { type, data } = event.data;
    
    switch (type) {
      case 'feishu_resize':
        // 处理尺寸调整
        document.documentElement.style.height = `${data.height}px`;
        break;
        
      case 'feishu_theme_change':
        // 处理主题切换
        document.documentElement.setAttribute('data-theme', data.theme);
        break;
        
      case 'feishu_refresh':
        // 处理刷新请求
        window.location.reload();
        break;
    }
  });

  // 向飞书发送就绪消息
  window.parent.postMessage({
    type: 'component_ready',
    componentType: 'dashboard',
    data: {
      height: document.body.scrollHeight,
      title: '实时数据看板'
    }
  }, '*');
}

// 组件包装器
const DashboardApp: React.FC = () => {
  const feishuContext = getFeishuContext();
  
  React.useEffect(() => {
    setupFeishuMessaging();
    
    // 设置页面标题
    document.title = '星趣App - 实时数据看板';
    
    // 设置主题
    if (feishuContext?.theme) {
      document.documentElement.setAttribute('data-theme', feishuContext.theme);
    }
  }, [feishuContext]);

  return (
    <DashboardComponent 
      feishuContext={feishuContext}
      autoRefresh={true}
      refreshInterval={30000}
    />
  );
};

// 渲染应用
const root = ReactDOM.createRoot(document.getElementById('root')!);
root.render(
  <React.StrictMode>
    <DashboardApp />
  </React.StrictMode>
);

// 错误处理
window.addEventListener('error', (event) => {
  console.error('Dashboard component error:', event.error);
  
  // 向飞书报告错误
  window.parent.postMessage({
    type: 'component_error',
    componentType: 'dashboard',
    error: {
      message: event.error?.message,
      stack: event.error?.stack
    }
  }, '*');
});

// 性能监控
window.addEventListener('load', () => {
  const loadTime = performance.now();
  console.log(`Dashboard component loaded in ${loadTime.toFixed(2)}ms`);
  
  // 向飞书报告加载性能
  window.parent.postMessage({
    type: 'component_performance',
    componentType: 'dashboard',
    metrics: {
      loadTime,
      timestamp: new Date().toISOString()
    }
  }, '*');
});