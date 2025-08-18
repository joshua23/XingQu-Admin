import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import '@xingqu/shared/src/styles/globals.css';

// 设置页面标题和元信息
document.title = '星趣App - 后台管理系统';

// 设置主题
const urlParams = new URLSearchParams(window.location.search);
const theme = urlParams.get('theme') || 'light';
document.documentElement.setAttribute('data-theme', theme);

// 渲染应用
const root = ReactDOM.createRoot(document.getElementById('root')!);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// 错误处理
window.addEventListener('error', (event) => {
  console.error('Admin system error:', event.error);
  
  // 向飞书报告错误
  window.parent.postMessage({
    type: 'component_error',
    componentType: 'admin_system',
    error: {
      message: event.error?.message,
      stack: event.error?.stack
    }
  }, '*');
});

// 性能监控
window.addEventListener('load', () => {
  const loadTime = performance.now();
  console.log(`Admin system loaded in ${loadTime.toFixed(2)}ms`);
  
  // 向飞书报告加载性能
  window.parent.postMessage({
    type: 'component_performance',
    componentType: 'admin_system',
    metrics: {
      loadTime,
      timestamp: new Date().toISOString()
    }
  }, '*');
});