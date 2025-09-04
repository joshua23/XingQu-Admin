# 🎵 音频素材管理系统配置指南

## 📋 配置状态

### ✅ 已完成配置
1. **数据库表结构** - 完成 ✅
   - `xq_material_categories` - 素材分类表
   - `xq_audio_materials` - 音频素材表
   - 包含触发器、索引、约束等

2. **RLS权限策略** - 完成 ✅
   - 公开用户可查看活跃的分类和素材
   - 管理员可完全管理分类和素材
   - 基于email关联管理员权限

3. **示例数据** - 完成 ✅
   - 创建了5个基础分类：背景音乐、音效、自然音、人声、乐器

### 🔄 需要手动配置
**Supabase Storage Bucket配置** - 需要在Dashboard中创建

## 🛠️ 手动配置步骤

### 1. 创建Storage Bucket

请登录 [Supabase Dashboard](https://supabase.com/dashboard) 并按以下步骤操作：

1. **进入Storage页面**
   - 在左侧菜单选择 "Storage"
   - 点击 "Create a new bucket"

2. **配置Bucket设置**
   ```
   Bucket名称: audio-materials
   公开访问: 关闭 (Private)
   文件大小限制: 50MB
   允许的MIME类型: 
     - audio/mpeg
     - audio/mp3  
     - audio/wav
     - audio/ogg
     - audio/aac
   ```

3. **设置Storage RLS策略**
   在创建Bucket后，进入Policies标签页，添加以下策略：

   **策略1: 公开读取访问**
   ```sql
   CREATE POLICY "Public read access for audio materials" 
   ON storage.objects
   FOR SELECT 
   TO public
   USING (bucket_id = 'audio-materials');
   ```

   **策略2: 认证用户上传权限**
   ```sql
   CREATE POLICY "Authenticated upload access for audio materials"
   ON storage.objects  
   FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'audio-materials');
   ```

   **策略3: 认证用户更新权限**
   ```sql
   CREATE POLICY "Authenticated update access for audio materials"
   ON storage.objects
   FOR UPDATE
   TO authenticated
   USING (bucket_id = 'audio-materials')
   WITH CHECK (bucket_id = 'audio-materials');
   ```

   **策略4: 认证用户删除权限**
   ```sql
   CREATE POLICY "Authenticated delete access for audio materials"
   ON storage.objects
   FOR DELETE
   TO authenticated
   USING (bucket_id = 'audio-materials');
   ```

## 📊 数据库表结构

### xq_material_categories (素材分类表)
```sql
id          - UUID (主键)
name        - 分类名称 (唯一)
description - 分类描述
icon        - 分类图标
sort_order  - 排序序号
is_active   - 是否激活
created_at  - 创建时间
updated_at  - 更新时间
```

### xq_audio_materials (音频素材表)
```sql
id               - UUID (主键)
title            - 素材标题
description      - 素材描述
file_name        - 文件名
file_path        - 文件路径 (唯一)
file_size        - 文件大小
duration_seconds - 时长(秒)
category_id      - 分类ID (外键)
tags             - 标签数组
is_active        - 是否激活
download_count   - 下载次数
created_by       - 创建者ID
created_at       - 创建时间
updated_at       - 更新时间
```

## 🔍 验证配置

执行以下SQL验证配置是否正确：

```bash
# 检查数据表
./scripts/db-connection.sh -c "
SELECT 
  table_name, 
  COUNT(*) as record_count 
FROM (
  SELECT 'categories' as table_name FROM xq_material_categories
  UNION ALL 
  SELECT 'materials' as table_name FROM xq_audio_materials
) counts 
GROUP BY table_name;
"

# 检查分类数据
./scripts/db-connection.sh -c "
SELECT name, icon, sort_order 
FROM xq_material_categories 
ORDER BY sort_order;
"
```

## 🚀 下一步

配置完成后，您可以：

1. **开始前端开发** - 创建素材管理页面
2. **API接口开发** - 为星趣App提供素材接口
3. **上传测试** - 测试音频文件上传功能

## 📞 技术支持

如果配置过程中遇到问题，请检查：
- Supabase项目是否启用了Storage功能
- Service Role Key权限是否正确
- RLS策略是否正确应用

---

*配置完成时间: 2025-09-04*  
*项目: 星趣后台管理系统*