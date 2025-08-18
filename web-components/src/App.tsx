import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import DashboardComponent from '@components/dashboard/src/DashboardComponent';
import UserManagementComponent from '@components/user-management/src/UserManagementComponent';
import ContentModerationComponent from '@components/content-moderation/src/ContentModerationComponent';
import MobileDataMonitor from './components/MobileDataMonitor';
import { FeishuContext } from '@xingqu/shared/src/types';

function App() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [feishuContext, setFeishuContext] = useState<FeishuContext | undefined>();

  // 获取飞书上下文参数
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const userId = urlParams.get('feishu_user_id');
    
    if (userId) {
      setFeishuContext({
        userId,
        userName: urlParams.get('feishu_user_name') || '未知用户',
        tableId: urlParams.get('feishu_table_id') || '',
        permissions: (urlParams.get('permissions') || '').split(',').filter(Boolean),
        locale: (urlParams.get('locale') as 'zh-CN' | 'en-US') || 'zh-CN',
        theme: (urlParams.get('theme') as 'light' | 'dark') || 'light'
      });
    }
  }, []);

  // 飞书消息通信设置
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
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
          document.documentElement.style.height = `${data.height}px`;
          break;
        case 'feishu_theme_change':
          document.documentElement.setAttribute('data-theme', data.theme);
          break;
        case 'feishu_refresh':
          window.location.reload();
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    
    // 向飞书发送就绪消息
    window.parent.postMessage({
      type: 'component_ready',
      componentType: 'admin_system',
      data: {
        height: document.body.scrollHeight,
        title: '星趣App后台管理系统'
      }
    }, '*');

    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return (
    <Router>
      <div className="flex h-screen bg-bg-secondary">
        <Sidebar 
          collapsed={sidebarCollapsed} 
          onToggle={setSidebarCollapsed}
          feishuContext={feishuContext}
        />
        
        <main className={`flex-1 overflow-hidden transition-all duration-300 ${
          sidebarCollapsed ? 'ml-16' : 'ml-64'
        }`}>
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={
              <DashboardComponent 
                feishuContext={feishuContext}
                autoRefresh={true}
                refreshInterval={30000}
              />
            } />
            <Route path="/users" element={
              <UserManagementComponent feishuContext={feishuContext} />
            } />
            <Route path="/moderation" element={
              <ContentModerationComponent feishuContext={feishuContext} />
            } />
            <Route path="/mobile" element={
              <MobileDataMonitor />
            } />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;