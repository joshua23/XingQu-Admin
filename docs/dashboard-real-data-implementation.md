# Dashboard 真实数据配置方案

## 实施完成日期
2025-01-02

## 数据库查询结果

### 1. Supabase数据表统计（xq_前缀）
```
表名                          | 数据量
----------------------------|-------
xq_tracking_events          | 35行
xq_user_sessions            | 3行  
xq_feedback                 | 1行
xq_user_profiles            | 1行
xq_user_settings            | 1行
xq_account_deletion_requests| 0行
xq_agents                   | 0行
xq_avatars                  | 0行
xq_background_music         | 0行
xq_fm_programs              | 0行
xq_user_blacklist           | 0行
xq_voices                   | 0行
```

### 2. 事件类型分布
```
事件类型                    | 数量
---------------------------|-----
page_view                  | 25
tab_switch                 | 3
app_launch                 | 3
profile_edit_option_tap    | 1
feedback_type_select       | 1
play_bgm_changed          | 1
profile_edit_button_tap    | 1
```

## Dashboard指标映射

### 主要指标卡片（已配置）
1. **总用户数**: 从 `xq_user_profiles` 表统计
2. **今日活跃**: 从 `xq_tracking_events` 表统计24小时内的独立用户
3. **今日收入**: 暂无支付数据，显示为0
4. **转化率**: 活跃用户/总用户数的百分比

### 快速统计模块（已配置）
1. **用户概况**
   - 新用户注册: `xq_user_profiles` 总数
   - 活跃用户: 24小时内有事件的用户数
   - 会员用户: `is_member=true` 的用户数

2. **用户行为**
   - 页面访问量: `event_type='page_view'` 的事件数
   - 平均停留时长: `duration_seconds` 字段平均值
   - 会话总数: `xq_user_sessions` 表总数

3. **财务数据**
   - 暂无支付相关表，显示为0

### 今日目标进度条（已配置）
- 收入目标: 0/1000元
- 新用户注册: 1/100人
- 活跃用户: 1/10人

## 已完成的代码修改

### 1. 数据服务层（supabase.ts）
- 修正了字段名错误：`session_duration` → `duration_seconds`
- 添加了会员用户和页面浏览量统计
- 优化了并行查询逻辑

### 2. Dashboard页面（Dashboard.tsx）
- 扩展了 `DashboardStats` 接口，添加 `memberUsers` 和 `pageViews`
- 更新了主要指标卡片，使用真实数据
- 更新了快速统计模块，动态显示数据
- 调整了目标进度条，使用实际值

## 使用说明

### 查询数据库
```bash
# 查询所有xq_表及数据量
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT 
    schemaname, 
    relname as tablename, 
    n_live_tup as row_count 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
  AND relname LIKE 'xq_%' 
ORDER BY n_live_tup DESC, relname;"
```

### 查看实时数据
1. 启动开发服务器：`npm run dev`
2. 访问Dashboard页面
3. 点击"刷新"按钮获取最新数据
4. 数据每15分钟自动刷新

## 注意事项

1. **数据量较少**: 当前数据库中数据量很少，适合开发测试
2. **支付数据缺失**: 没有支付相关表，财务指标暂时为0
3. **会话时长**: 当前所有会话的 `duration_seconds` 为0，需要前端记录
4. **实时性**: Dashboard设置了15分钟自动刷新，可手动刷新

## 后续优化建议

1. **添加支付表**: 创建订单/支付相关表以支持财务统计
2. **完善会话追踪**: 记录用户会话的实际持续时间
3. **增加数据维度**: 添加更多统计维度如地域、设备类型等
4. **性能优化**: 当数据量增大后，考虑添加缓存层或聚合表
5. **添加趋势分析**: 实现环比、同比等趋势指标

## 验证步骤

1. ✅ 查询数据库获取实际表结构和数据
2. ✅ 分析Dashboard页面的指标需求
3. ✅ 修正数据服务层的字段映射错误
4. ✅ 更新Dashboard组件使用真实数据
5. ✅ 测试数据加载和显示功能

## 总结

已成功完成Dashboard与Supabase数据库的集成，所有指标均配置为使用真实数据。当前显示的数据准确反映了数据库中的实际情况。