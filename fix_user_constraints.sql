-- 修复用户数据表约束问题
-- 解决首页-精选页点赞、评论、关注功能的外键约束错误

-- 1. 检查并修复 users 表结构
-- 确保 users 表有正确的字段结构
DO $$ 
BEGIN
    -- 检查 users 表是否存在 phone 字段的唯一约束问题
    -- 允许空值的 phone 字段不应该有唯一约束
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' 
        AND constraint_name = 'users_phone_key'
    ) THEN
        ALTER TABLE users DROP CONSTRAINT users_phone_key;
        RAISE NOTICE '已删除 users_phone_key 约束';
    END IF;
    
    -- 添加新的约束，允许多个空值
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' 
        AND constraint_name = 'users_phone_unique_when_not_null'
    ) THEN
        -- 创建部分唯一索引，只对非空 phone 值进行唯一约束
        CREATE UNIQUE INDEX users_phone_unique_when_not_null 
        ON users (phone) 
        WHERE phone IS NOT NULL AND phone != '';
        RAISE NOTICE '已创建 users_phone_unique_when_not_null 索引';
    END IF;
END $$;

-- 2. 确保匿名用户能正确插入到 users 表
-- 创建一个函数来安全地确保用户存在
CREATE OR REPLACE FUNCTION ensure_user_exists(user_id UUID, user_email TEXT DEFAULT NULL, user_phone TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    -- 尝试插入用户，如果已存在则忽略
    INSERT INTO users (id, email, phone, created_at, updated_at)
    VALUES (
        user_id, 
        user_email,
        CASE WHEN user_phone = '' THEN NULL ELSE user_phone END, -- 将空字符串转换为 NULL
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        updated_at = NOW(),
        email = COALESCE(users.email, EXCLUDED.email),
        phone = CASE 
            WHEN EXCLUDED.phone IS NOT NULL AND EXCLUDED.phone != '' THEN EXCLUDED.phone 
            ELSE users.phone 
        END;
END;
$$ LANGUAGE plpgsql;

-- 3. 修复现有的匿名用户数据
-- 查找所有在 auth.users 中存在但在 public.users 中不存在的用户
INSERT INTO users (id, email, phone, created_at, updated_at)
SELECT 
    au.id,
    au.email,
    NULL, -- 匿名用户通常没有手机号
    au.created_at,
    au.updated_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 4. 创建触发器函数，自动为新的 auth.users 创建 public.users 记录
CREATE OR REPLACE FUNCTION create_public_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, phone, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        NULL, -- 新用户默认没有手机号
        NEW.created_at,
        NEW.updated_at
    )
    ON CONFLICT (id) DO UPDATE SET
        email = COALESCE(users.email, EXCLUDED.email),
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 创建触发器（如果不存在）
DROP TRIGGER IF EXISTS create_public_user_trigger ON auth.users;
CREATE TRIGGER create_public_user_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_public_user();

-- 6. 验证修复结果
DO $$
DECLARE
    auth_user_count INTEGER;
    public_user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO auth_user_count FROM auth.users;
    SELECT COUNT(*) INTO public_user_count FROM users;
    
    RAISE NOTICE '认证用户数量: %, 公共用户数量: %', auth_user_count, public_user_count;
    
    IF public_user_count < auth_user_count THEN
        RAISE WARNING '存在用户数据不一致，请检查用户同步';
    ELSE
        RAISE NOTICE '✅ 用户数据一致性检查通过';
    END IF;
END $$;

-- 7. 创建用于测试的存储过程
CREATE OR REPLACE FUNCTION test_user_operations(test_user_id UUID)
RETURNS TABLE(
    operation TEXT,
    success BOOLEAN,
    message TEXT
) AS $$
BEGIN
    -- 测试确保用户存在
    BEGIN
        PERFORM ensure_user_exists(test_user_id);
        RETURN QUERY SELECT '确保用户存在'::TEXT, TRUE, '成功'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT '确保用户存在'::TEXT, FALSE, SQLERRM::TEXT;
    END;
    
    -- 测试插入点赞
    BEGIN
        INSERT INTO likes (user_id, target_id, target_type) 
        VALUES (test_user_id, '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'character')
        ON CONFLICT (user_id, target_id, target_type) DO NOTHING;
        RETURN QUERY SELECT '插入点赞'::TEXT, TRUE, '成功'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT '插入点赞'::TEXT, FALSE, SQLERRM::TEXT;
    END;
    
    -- 测试插入关注
    BEGIN
        INSERT INTO character_follows (user_id, character_id) 
        VALUES (test_user_id, '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
        ON CONFLICT (user_id, character_id) DO NOTHING;
        RETURN QUERY SELECT '插入关注'::TEXT, TRUE, '成功'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT '插入关注'::TEXT, FALSE, SQLERRM::TEXT;
    END;
    
    -- 测试插入评论
    BEGIN
        INSERT INTO comments (user_id, target_id, target_type, content) 
        VALUES (test_user_id, '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'character', '测试评论');
        RETURN QUERY SELECT '插入评论'::TEXT, TRUE, '成功'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT '插入评论'::TEXT, FALSE, SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- 8. 运行测试
SELECT * FROM test_user_operations('c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d');

COMMIT;