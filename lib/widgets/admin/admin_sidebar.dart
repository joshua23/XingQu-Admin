import 'package:flutter/material.dart';

/// 后台管理系统侧边导航栏
/// 基于insight-builder的AnalyticsSidebar设计
class AdminSidebar extends StatelessWidget {
  final String activeModule;
  final Function(String) onModuleChanged;

  const AdminSidebar({
    super.key,
    required this.activeModule,
    required this.onModuleChanged,
  });

  static const List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(
      id: 'overview',
      label: '数据总览',
      icon: Icons.dashboard_outlined,
      description: '系统关键指标概览',
    ),
    SidebarMenuItem(
      id: 'user-analytics', 
      label: '用户分析',
      icon: Icons.people_outline,
      description: '用户基础信息统计',
    ),
    SidebarMenuItem(
      id: 'behavior-analytics',
      label: '行为分析', 
      icon: Icons.analytics_outlined,
      description: '用户行为追踪数据',
    ),
    SidebarMenuItem(
      id: 'session-analytics',
      label: '会话分析',
      icon: Icons.access_time_outlined, 
      description: '用户会话统计',
    ),
    SidebarMenuItem(
      id: 'realtime',
      label: '实时监控',
      icon: Icons.monitor_heart_outlined,
      description: '实时系统指标',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B2E),
        border: Border(
          right: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 头部logo区域
          _buildHeader(),
          
          // 导航菜单
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: _menuItems
                    .map((item) => _buildMenuItem(item))
                    .toList(),
              ),
            ),
          ),
          
          // 底部设置
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '星趣数据中心',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'XingQu Analytics',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final isActive = activeModule == item.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onModuleChanged(item.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFFFFD700).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive 
                ? Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive 
                    ? const Color(0xFFFFD700)
                    : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[300],
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildFooterButton(
            icon: Icons.settings_outlined,
            label: '系统设置',
            onTap: () {
              // TODO: 实现设置功能
            },
          ),
          const SizedBox(height: 8),
          _buildFooterButton(
            icon: Icons.help_outline,
            label: '帮助中心',
            onTap: () {
              // TODO: 实现帮助功能
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 侧边栏菜单项模型
class SidebarMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final String? description;

  const SidebarMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.description,
  });
}