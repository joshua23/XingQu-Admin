-- 修复社交功能表的行级安全策略 (RLS) 
-- 这是修复点赞、评论、关注功能失败的关键补丁

-- 启用行级安全
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;

-- ========== 点赞表策略 ==========
-- 所有人可以查看点赞
CREATE POLICY "Anyone can view likes" ON likes
    FOR SELECT USING (true);

-- 用户可以管理自己的点赞
CREATE POLICY "Users can manage own likes" ON likes
    FOR ALL USING (auth.uid() = user_id);

-- ========== 评论表策略 ==========
-- 所有人可以查看评论
CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

-- 用户可以管理自己的评论
CREATE POLICY "Users can manage own comments" ON comments
    FOR ALL USING (auth.uid() = user_id);

-- ========== 关注表策略 ==========
-- 所有人可以查看关注关系
CREATE POLICY "Anyone can view follows" ON follows
    FOR SELECT USING (true);

-- 用户可以管理自己的关注
CREATE POLICY "Users can manage own follows" ON follows
    FOR ALL USING (auth.uid() = user_id);

-- ========== 角色关注表策略 ==========
-- 所有人可以查看角色关注
CREATE POLICY "Anyone can view character follows" ON character_follows
    FOR SELECT USING (true);

-- 用户可以管理自己的角色关注
CREATE POLICY "Users can manage own character follows" ON character_follows
    FOR ALL USING (auth.uid() = user_id);

-- ========== 匿名用户支持 ==========
-- 为了支持匿名用户，我们需要确保匿名用户也能使用这些功能
-- 注意：这些策略假设Supabase项目启用了匿名认证

-- 用户分析表策略（支持匿名用户）
CREATE POLICY "Anyone can insert analytics" ON user_analytics
    FOR INSERT WITH CHECK (true);

-- 如果需要，可以为匿名用户创建更宽松的策略
-- 但出于安全考虑，建议保持当前的用户验证策略

-- ========== 索引优化 ==========
-- 为社交功能添加性能索引
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_target ON comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_user ON character_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character ON character_follows(character_id);

-- ========== 验证查询 ==========
-- 执行完上述SQL后，可以运行以下查询验证设置：
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename IN ('likes', 'comments', 'follows', 'character_follows');
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename IN ('likes', 'comments', 'follows', 'character_follows');