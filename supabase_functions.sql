-- Supabase数据库函数和存储过程
-- 在Supabase SQL编辑器中执行，提供后端业务逻辑支持

-- ============================================================================
-- 计数器更新函数
-- ============================================================================

-- 增加播放次数
CREATE OR REPLACE FUNCTION increment_play_count(audio_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE audio_contents 
    SET play_count = play_count + 1 
    WHERE id = audio_id;
END;
$$ LANGUAGE plpgsql;

-- 增加点赞数
CREATE OR REPLACE FUNCTION increment_like_count(target_table TEXT, target_id UUID)
RETURNS void AS $$
BEGIN
    CASE target_table
        WHEN 'ai_characters' THEN
            UPDATE ai_characters SET follower_count = follower_count + 1 WHERE id = target_id;
        WHEN 'audio_contents' THEN
            UPDATE audio_contents SET like_count = like_count + 1 WHERE id = target_id;
        WHEN 'creation_items' THEN
            UPDATE creation_items SET like_count = like_count + 1 WHERE id = target_id;
        WHEN 'discovery_contents' THEN
            UPDATE discovery_contents SET like_count = like_count + 1 WHERE id = target_id;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 减少点赞数
CREATE OR REPLACE FUNCTION decrement_like_count(target_table TEXT, target_id UUID)
RETURNS void AS $$
BEGIN
    CASE target_table
        WHEN 'ai_characters' THEN
            UPDATE ai_characters SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = target_id;
        WHEN 'audio_contents' THEN
            UPDATE audio_contents SET like_count = GREATEST(like_count - 1, 0) WHERE id = target_id;
        WHEN 'creation_items' THEN
            UPDATE creation_items SET like_count = GREATEST(like_count - 1, 0) WHERE id = target_id;
        WHEN 'discovery_contents' THEN
            UPDATE discovery_contents SET like_count = GREATEST(like_count - 1, 0) WHERE id = target_id;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 点赞系统触发器函数
-- ============================================================================

-- 点赞计数触发器函数
CREATE OR REPLACE FUNCTION handle_like_count_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM increment_like_count(NEW.target_type, NEW.target_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM decrement_like_count(OLD.target_type, OLD.target_id);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 创建点赞计数触发器
DROP TRIGGER IF EXISTS like_count_trigger ON likes;
CREATE TRIGGER like_count_trigger
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW EXECUTE FUNCTION handle_like_count_change();

-- ============================================================================
-- 搜索和推荐功能
-- ============================================================================

-- 获取推荐AI角色
CREATE OR REPLACE FUNCTION get_recommended_characters(
    user_id UUID DEFAULT NULL,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    avatar_url TEXT,
    category VARCHAR,
    follower_count INTEGER,
    rating DECIMAL,
    is_followed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.avatar_url,
        c.category,
        c.follower_count,
        c.rating,
        CASE 
            WHEN user_id IS NOT NULL THEN 
                EXISTS(SELECT 1 FROM character_follows cf WHERE cf.user_id = $1 AND cf.character_id = c.id)
            ELSE FALSE
        END as is_followed
    FROM ai_characters c
    WHERE c.is_public = true AND c.is_active = true
    ORDER BY 
        c.is_featured DESC,
        c.follower_count DESC,
        c.rating DESC,
        c.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 获取热门音频内容
CREATE OR REPLACE FUNCTION get_trending_audios(
    limit_count INTEGER DEFAULT 10,
    category_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    description TEXT,
    cover_url TEXT,
    duration_seconds INTEGER,
    category VARCHAR,
    play_count INTEGER,
    like_count INTEGER,
    creator_nickname VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.title,
        a.description,
        a.cover_url,
        a.duration_seconds,
        a.category,
        a.play_count,
        a.like_count,
        u.nickname as creator_nickname
    FROM audio_contents a
    LEFT JOIN users u ON a.creator_id = u.id
    WHERE a.is_public = true 
        AND (category_filter IS NULL OR a.category = category_filter)
    ORDER BY 
        a.is_featured DESC,
        a.play_count DESC,
        a.like_count DESC,
        a.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 全文搜索函数
CREATE OR REPLACE FUNCTION search_content(
    search_query TEXT,
    content_types TEXT[] DEFAULT ARRAY['characters', 'audios', 'discoveries'],
    limit_per_type INTEGER DEFAULT 5
)
RETURNS TABLE (
    content_type TEXT,
    id UUID,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    relevance REAL
) AS $$
BEGIN
    -- 搜索AI角色
    IF 'characters' = ANY(content_types) THEN
        RETURN QUERY
        SELECT 
            'characters'::TEXT as content_type,
            c.id,
            c.name::TEXT as title,
            c.description,
            c.avatar_url as thumbnail_url,
            ts_rank(to_tsvector('simple', c.name || ' ' || COALESCE(c.description, '')), plainto_tsquery('simple', search_query)) as relevance
        FROM ai_characters c
        WHERE c.is_public = true 
            AND c.is_active = true
            AND (
                to_tsvector('simple', c.name || ' ' || COALESCE(c.description, '')) @@ plainto_tsquery('simple', search_query)
                OR c.name ILIKE '%' || search_query || '%'
                OR c.description ILIKE '%' || search_query || '%'
            )
        ORDER BY relevance DESC
        LIMIT limit_per_type;
    END IF;

    -- 搜索音频内容
    IF 'audios' = ANY(content_types) THEN
        RETURN QUERY
        SELECT 
            'audios'::TEXT as content_type,
            a.id,
            a.title::TEXT,
            a.description,
            a.cover_url as thumbnail_url,
            ts_rank(to_tsvector('simple', a.title || ' ' || COALESCE(a.description, '')), plainto_tsquery('simple', search_query)) as relevance
        FROM audio_contents a
        WHERE a.is_public = true 
            AND (
                to_tsvector('simple', a.title || ' ' || COALESCE(a.description, '')) @@ plainto_tsquery('simple', search_query)
                OR a.title ILIKE '%' || search_query || '%'
                OR a.description ILIKE '%' || search_query || '%'
            )
        ORDER BY relevance DESC
        LIMIT limit_per_type;
    END IF;

    -- 搜索发现内容
    IF 'discoveries' = ANY(content_types) THEN
        RETURN QUERY
        SELECT 
            'discoveries'::TEXT as content_type,
            d.id,
            d.title::TEXT,
            d.description,
            d.thumbnail_url,
            ts_rank(to_tsvector('simple', d.title || ' ' || COALESCE(d.description, '')), plainto_tsquery('simple', search_query)) as relevance
        FROM discovery_contents d
        WHERE 
            to_tsvector('simple', d.title || ' ' || COALESCE(d.description, '')) @@ plainto_tsquery('simple', search_query)
            OR d.title ILIKE '%' || search_query || '%'
            OR d.description ILIKE '%' || search_query || '%'
        ORDER BY relevance DESC
        LIMIT limit_per_type;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 用户行为分析函数
-- ============================================================================

-- 获取用户偏好分析
CREATE OR REPLACE FUNCTION get_user_preferences(user_id UUID)
RETURNS TABLE (
    preferred_categories TEXT[],
    interaction_count INTEGER,
    avg_session_duration INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    WITH user_interactions AS (
        SELECT 
            cf.character_id,
            c.category,
            COUNT(*) as interactions
        FROM character_follows cf
        JOIN ai_characters c ON cf.character_id = c.id
        WHERE cf.user_id = $1
        GROUP BY cf.character_id, c.category
        
        UNION ALL
        
        SELECT 
            aph.audio_id,
            ac.category,
            COUNT(*) as interactions
        FROM audio_play_history aph
        JOIN audio_contents ac ON aph.audio_id = ac.id
        WHERE aph.user_id = $1
        GROUP BY aph.audio_id, ac.category
    ),
    category_stats AS (
        SELECT 
            category,
            SUM(interactions) as total_interactions
        FROM user_interactions
        GROUP BY category
        ORDER BY total_interactions DESC
        LIMIT 5
    )
    SELECT 
        ARRAY_AGG(category) as preferred_categories,
        SUM(total_interactions)::INTEGER as interaction_count,
        INTERVAL '30 minutes' as avg_session_duration  -- 占位值，实际需要基于会话数据计算
    FROM category_stats;
END;
$$ LANGUAGE plpgsql;

-- 记录用户活跃度
CREATE OR REPLACE FUNCTION update_user_activity(
    user_id UUID,
    activity_type TEXT,
    activity_data JSONB DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO user_analytics (
        user_id, 
        event_type, 
        event_data,
        created_at
    ) VALUES (
        user_id, 
        activity_type, 
        activity_data,
        NOW()
    );
    
    -- 更新用户经验值
    UPDATE users 
    SET experience_points = experience_points + 
        CASE activity_type
            WHEN 'character_follow' THEN 5
            WHEN 'audio_play' THEN 3
            WHEN 'content_like' THEN 2
            WHEN 'comment_add' THEN 8
            WHEN 'creation_publish' THEN 20
            ELSE 1
        END
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 内容审核和管理函数
-- ============================================================================

-- 自动内容审核（简化版）
CREATE OR REPLACE FUNCTION auto_moderate_content(
    content_type TEXT,
    content_id UUID,
    content_text TEXT
)
RETURNS TEXT AS $$
DECLARE
    result TEXT := 'approved';
    sensitive_words TEXT[] := ARRAY['敏感词1', '敏感词2']; -- 实际应该从配置表读取
    word TEXT;
BEGIN
    -- 检查敏感词
    FOREACH word IN ARRAY sensitive_words
    LOOP
        IF content_text ILIKE '%' || word || '%' THEN
            result := 'rejected';
            EXIT;
        END IF;
    END LOOP;
    
    -- 记录审核日志
    INSERT INTO user_analytics (
        user_id, 
        event_type, 
        event_data
    ) VALUES (
        '00000000-0000-0000-0000-000000000000'::UUID, -- 系统用户ID
        'content_moderation',
        jsonb_build_object(
            'content_type', content_type,
            'content_id', content_id,
            'result', result
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 数据统计和分析函数
-- ============================================================================

-- 获取系统统计数据
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_characters BIGINT,
    total_audios BIGINT,
    total_creations BIGINT,
    daily_active_users BIGINT,
    total_plays BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users)::BIGINT as total_users,
        (SELECT COUNT(*) FROM ai_characters WHERE is_active = true)::BIGINT as total_characters,
        (SELECT COUNT(*) FROM audio_contents WHERE is_public = true)::BIGINT as total_audios,
        (SELECT COUNT(*) FROM creation_items WHERE status = 'published')::BIGINT as total_creations,
        (SELECT COUNT(DISTINCT user_id) FROM user_analytics WHERE created_at >= CURRENT_DATE)::BIGINT as daily_active_users,
        (SELECT SUM(play_count) FROM audio_contents)::BIGINT as total_plays;
END;
$$ LANGUAGE plpgsql;

-- 获取热门标签
CREATE OR REPLACE FUNCTION get_trending_tags(limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
    tag TEXT,
    usage_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH all_tags AS (
        SELECT unnest(tags) as tag FROM ai_characters WHERE tags IS NOT NULL
        UNION ALL
        SELECT unnest(tags) as tag FROM audio_contents WHERE tags IS NOT NULL
        UNION ALL
        SELECT unnest(tags) as tag FROM creation_items WHERE tags IS NOT NULL
    )
    SELECT 
        at.tag,
        COUNT(*) as usage_count
    FROM all_tags at
    GROUP BY at.tag
    ORDER BY usage_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 缓存和性能优化函数
-- ============================================================================

-- 刷新物化视图（如果有的话）
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS $$
BEGIN
    -- 这里可以刷新物化视图来提高查询性能
    -- REFRESH MATERIALIZED VIEW mv_trending_content;
    -- REFRESH MATERIALIZED VIEW mv_user_recommendations;
    NULL; -- 占位符
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 数据清理和维护函数
-- ============================================================================

-- 清理过期数据
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- 清理过期的用户会话
    DELETE FROM user_sessions 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- 清理过期的分析数据（保留90天）
    DELETE FROM user_analytics 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- 清理过期的播放历史（保留6个月）
    DELETE FROM audio_play_history 
    WHERE played_at < NOW() - INTERVAL '6 months';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 权限和安全函数
-- ============================================================================

-- 检查用户权限
CREATE OR REPLACE FUNCTION check_user_permission(
    user_id UUID,
    resource_type TEXT,
    resource_id UUID,
    action TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN := FALSE;
BEGIN
    CASE resource_type
        WHEN 'ai_character' THEN
            -- 检查是否是创建者
            SELECT (creator_id = user_id) INTO has_permission
            FROM ai_characters WHERE id = resource_id;
            
        WHEN 'audio_content' THEN
            SELECT (creator_id = user_id) INTO has_permission
            FROM audio_contents WHERE id = resource_id;
            
        WHEN 'creation_item' THEN
            SELECT (creator_id = user_id OR user_id = ANY(collaborators)) INTO has_permission
            FROM creation_items WHERE id = resource_id;
            
        ELSE
            has_permission := FALSE;
    END CASE;
    
    RETURN has_permission;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 创建定时任务（需要pg_cron扩展）
-- ============================================================================

-- 注意：以下需要在Supabase中启用pg_cron扩展
-- 每天清理过期数据
-- SELECT cron.schedule('cleanup-expired-data', '0 2 * * *', 'SELECT cleanup_expired_data();');

-- 每小时刷新缓存
-- SELECT cron.schedule('refresh-cache', '0 * * * *', 'SELECT refresh_materialized_views();');