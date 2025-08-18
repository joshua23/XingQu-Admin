-- 紧急修复用户数据问题的SQL脚本
-- 直接在Supabase SQL编辑器中执行

-- 1. 首先检查当前auth.users中的所有用户
SELECT 'Auth用户列表' as info, id, email, phone, created_at 
FROM auth.users 
ORDER BY created_at DESC;

-- 2. 检查public.users中的用户
SELECT 'Public用户列表' as info, id, phone, nickname, created_at 
FROM users 
ORDER BY created_at DESC;

-- 3. 找出在auth.users中存在但在public.users中不存在的用户
SELECT '缺失的用户' as info, au.id, au.email, au.created_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- 4. 删除users表中的phone唯一约束（如果存在）
DO $$ 
BEGIN
    -- 删除可能导致问题的唯一约束
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' 
        AND constraint_name = 'users_phone_key'
    ) THEN
        ALTER TABLE users DROP CONSTRAINT users_phone_key;
        RAISE NOTICE '已删除 users_phone_key 约束';
    END IF;
END $$;

-- 5. 为所有auth.users创建对应的public.users记录
INSERT INTO users (id, email, phone, nickname, created_at, updated_at)
SELECT 
    au.id,
    au.email,
    NULL, -- 设置为NULL避免唯一约束冲突
    COALESCE(au.raw_user_meta_data->>'name', '用户' || substr(au.id::text, 1, 8)),
    au.created_at,
    au.updated_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 6. 创建部分唯一索引（只对非空phone值进行唯一约束）
DROP INDEX IF EXISTS users_phone_unique_when_not_null;
CREATE UNIQUE INDEX users_phone_unique_when_not_null 
ON users (phone) 
WHERE phone IS NOT NULL AND phone != '';

-- 7. 验证修复结果
SELECT 
    'Auth用户数' as metric,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Public用户数' as metric,
    COUNT(*) as count
FROM users
UNION ALL
SELECT 
    '缺失用户数' as metric,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- 8. 检查并修复可能的RLS策略问题
-- 确保用户可以插入自己的数据
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- 9. 检查user_analytics表的RLS策略
DROP POLICY IF EXISTS "Users can insert own analytics" ON user_analytics;
CREATE POLICY "Users can insert own analytics" ON user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own analytics" ON user_analytics;
CREATE POLICY "Users can view own analytics" ON user_analytics
    FOR SELECT USING (auth.uid() = user_id);

-- 10. 检查likes表的RLS策略
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
CREATE POLICY "Users can manage own likes" ON likes
    FOR ALL USING (auth.uid() = user_id);

-- 11. 检查character_follows表的RLS策略
DROP POLICY IF EXISTS "Users can manage own follows" ON character_follows;
CREATE POLICY "Users can manage own follows" ON character_follows
    FOR ALL USING (auth.uid() = user_id);

-- 12. 检查comments表的RLS策略
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;
CREATE POLICY "Users can manage own comments" ON comments
    FOR ALL USING (auth.uid() = user_id);

-- 13. 最终检查 - 显示当前状态
SELECT 'FINAL CHECK' as status;

SELECT 
    'Users表记录数' as check_item,
    COUNT(*) as count
FROM users;

SELECT 
    'Analytics表记录数' as check_item,
    COUNT(*) as count
FROM user_analytics;

SELECT 
    '外键约束检查' as check_item,
    COUNT(*) as orphaned_records
FROM user_analytics ua
LEFT JOIN users u ON ua.user_id = u.id
WHERE u.id IS NULL;