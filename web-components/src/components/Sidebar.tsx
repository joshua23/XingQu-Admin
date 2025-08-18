import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  BarChart3,
  Users,
  Shield,
  Menu,
  X,
  Star,
  User,
  Smartphone
} from 'lucide-react';
import { FeishuContext } from '@xingqu/shared/src/types';

interface SidebarProps {
  collapsed: boolean;
  onToggle: (collapsed: boolean) => void;
  feishuContext?: FeishuContext;
}

const Sidebar: React.FC<SidebarProps> = ({ collapsed, onToggle, feishuContext }) => {
  const navigation = [
    {
      name: '数据看板',
      href: '/dashboard',
      icon: BarChart3,
      description: '实时数据统计'
    },
    {
      name: '用户管理',
      href: '/users',
      icon: Users,
      description: '用户信息管理'
    },
    {
      name: '内容审核',
      href: '/moderation',
      icon: Shield,
      description: '内容审核中心'
    },
    {
      name: '移动端监控',
      href: '/mobile',
      icon: Smartphone,
      description: 'iOS模拟器数据'
    }
  ];

  return (
    <div className={`fixed left-0 top-0 h-full bg-bg-primary border-r border-border-primary transition-all duration-300 z-50 ${
      collapsed ? 'w-16' : 'w-64'
    }`}>
      {/* 头部 */}
      <div className="flex items-center justify-between p-4 border-b border-border-secondary">
        {!collapsed && (
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-accent-primary rounded-lg flex items-center justify-center">
              <Star className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-text-primary">星趣管理</h1>
              <p className="text-xs text-text-tertiary">后台管理系统</p>
            </div>
          </div>
        )}
        
        <button
          onClick={() => onToggle(!collapsed)}
          className="p-2 rounded-lg hover:bg-bg-hover transition-colors"
        >
          {collapsed ? (
            <Menu className="w-5 h-5 text-text-secondary" />
          ) : (
            <X className="w-5 h-5 text-text-secondary" />
          )}
        </button>
      </div>

      {/* 用户信息 */}
      {feishuContext && !collapsed && (
        <div className="p-4 border-b border-border-secondary">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-accent-light rounded-full flex items-center justify-center">
              <User className="w-5 h-5 text-accent-primary" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-text-primary truncate">
                {feishuContext.userName}
              </p>
              <p className="text-xs text-text-tertiary truncate">
                飞书用户 • {feishuContext.permissions.length || 0} 权限
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 导航菜单 */}
      <nav className="flex-1 overflow-y-auto p-4">
        <div className="space-y-2">
          {navigation.map((item) => (
            <NavLink
              key={item.name}
              to={item.href}
              className={({ isActive }) =>
                `flex items-center space-x-3 p-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-accent-primary text-white'
                    : 'text-text-secondary hover:bg-bg-hover hover:text-text-primary'
                }`
              }
            >
              <item.icon className={`w-5 h-5 flex-shrink-0 ${collapsed ? 'mx-auto' : ''}`} />
              {!collapsed && (
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium">{item.name}</p>
                  <p className="text-xs opacity-75">{item.description}</p>
                </div>
              )}
            </NavLink>
          ))}
        </div>
      </nav>

      {/* 底部信息 */}
      {!collapsed && (
        <div className="p-4 border-t border-border-secondary">
          <div className="text-center">
            <p className="text-xs text-text-tertiary">
              星趣App v1.0.0
            </p>
            <p className="text-xs text-text-tertiary mt-1">
              Powered by Supabase
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default Sidebar;