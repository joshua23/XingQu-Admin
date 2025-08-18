import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_agent.dart';
import 'supabase_service.dart';

/// AI智能体管理服务
/// 处理智能体创建、配置、使用等功能
class AgentManagementService {
  static final AgentManagementService _instance = AgentManagementService._internal();
  factory AgentManagementService() => _instance;
  AgentManagementService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// 创建自定义智能体
  Future<CustomAgent> createCustomAgent({
    required String userId,
    required String agentName,
    required String description,
    required String systemPrompt,
    required Map<String, dynamic> configuration,
    String? avatarUrl,
    List<String>? capabilities,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    try {
      debugPrint('🤖 创建自定义智能体: $agentName');
      
      final agentData = {
        'user_id': userId,
        'agent_name': agentName,
        'description': description,
        'system_prompt': systemPrompt,
        'configuration': configuration,
        'avatar_url': avatarUrl,
        'capabilities': capabilities ?? [],
        'tags': tags ?? [],
        'is_public': isPublic,
        'is_active': true,
        'usage_count': 0,
        'rating_score': 0.0,
        'rating_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('custom_agents')
          .insert(agentData)
          .select()
          .single();

      final agent = CustomAgent.fromJson(response);
      debugPrint('✅ 智能体创建成功: ${agent.agentName}');
      return agent;
    } catch (e) {
      debugPrint('❌ 创建智能体失败: $e');
      throw Exception('创建智能体失败: $e');
    }
  }

  /// 获取用户的智能体列表
  Future<List<CustomAgent>> getUserAgents(String userId) async {
    try {
      debugPrint('👤 获取用户智能体: $userId');
      
      final response = await _client
          .from('custom_agents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final agents = (response as List)
          .map((json) => CustomAgent.fromJson(json))
          .toList();

      debugPrint('✅ 获取到 ${agents.length} 个用户智能体');
      return agents;
    } catch (e) {
      debugPrint('❌ 获取用户智能体失败: $e');
      return [];
    }
  }

  /// 获取公开的智能体列表
  Future<List<CustomAgent>> getPublicAgents({
    int limit = 50,
    String? category,
    String? searchQuery,
  }) async {
    try {
      debugPrint('🌍 获取公开智能体: limit=$limit, category=$category');
      
      var query = _client
          .from('custom_agents')
          .select()
          .eq('is_public', true)
          .eq('is_active', true);

      if (category != null) {
        query = query.contains('tags', [category]);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('agent_name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order('rating_score', ascending: false)
          .order('usage_count', ascending: false)
          .limit(limit);

      final agents = (response as List)
          .map((json) => CustomAgent.fromJson(json))
          .toList();

      debugPrint('✅ 获取到 ${agents.length} 个公开智能体');
      return agents;
    } catch (e) {
      debugPrint('❌ 获取公开智能体失败: $e');
      return [];
    }
  }

  /// 获取热门智能体
  Future<List<CustomAgent>> getPopularAgents({int limit = 20}) async {
    try {
      debugPrint('🔥 获取热门智能体: limit=$limit');
      
      final response = await _client
          .from('custom_agents')
          .select()
          .eq('is_public', true)
          .eq('is_active', true)
          .gte('usage_count', 10)
          .order('usage_count', ascending: false)
          .limit(limit);

      final agents = (response as List)
          .map((json) => CustomAgent.fromJson(json))
          .toList();

      debugPrint('✅ 获取到 ${agents.length} 个热门智能体');
      return agents;
    } catch (e) {
      debugPrint('❌ 获取热门智能体失败: $e');
      return [];
    }
  }

  /// 获取高评分智能体
  Future<List<CustomAgent>> getHighRatedAgents({int limit = 20}) async {
    try {
      debugPrint('⭐ 获取高评分智能体: limit=$limit');
      
      final response = await _client
          .from('custom_agents')
          .select()
          .eq('is_public', true)
          .eq('is_active', true)
          .gte('rating_count', 5)
          .gte('rating_score', 4.0)
          .order('rating_score', ascending: false)
          .limit(limit);

      final agents = (response as List)
          .map((json) => CustomAgent.fromJson(json))
          .toList();

      debugPrint('✅ 获取到 ${agents.length} 个高评分智能体');
      return agents;
    } catch (e) {
      debugPrint('❌ 获取高评分智能体失败: $e');
      return [];
    }
  }

  /// 根据ID获取智能体详情
  Future<CustomAgent?> getAgentById(String agentId) async {
    try {
      debugPrint('🔍 获取智能体详情: $agentId');
      
      final response = await _client
          .from('custom_agents')
          .select()
          .eq('agent_id', agentId)
          .single();

      final agent = CustomAgent.fromJson(response);
      debugPrint('✅ 智能体详情获取成功: ${agent.agentName}');
      return agent;
    } catch (e) {
      debugPrint('❌ 获取智能体详情失败: $e');
      return null;
    }
  }

  /// 更新智能体信息
  Future<CustomAgent> updateAgent({
    required String agentId,
    String? agentName,
    String? description,
    String? systemPrompt,
    Map<String, dynamic>? configuration,
    String? avatarUrl,
    List<String>? capabilities,
    List<String>? tags,
    bool? isPublic,
    bool? isActive,
  }) async {
    try {
      debugPrint('🔧 更新智能体: $agentId');
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (agentName != null) updateData['agent_name'] = agentName;
      if (description != null) updateData['description'] = description;
      if (systemPrompt != null) updateData['system_prompt'] = systemPrompt;
      if (configuration != null) updateData['configuration'] = configuration;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (capabilities != null) updateData['capabilities'] = capabilities;
      if (tags != null) updateData['tags'] = tags;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _client
          .from('custom_agents')
          .update(updateData)
          .eq('agent_id', agentId)
          .select()
          .single();

      final agent = CustomAgent.fromJson(response);
      debugPrint('✅ 智能体更新成功: ${agent.agentName}');
      return agent;
    } catch (e) {
      debugPrint('❌ 更新智能体失败: $e');
      throw Exception('更新智能体失败: $e');
    }
  }

  /// 删除智能体
  Future<void> deleteAgent(String agentId) async {
    try {
      debugPrint('🗑️ 删除智能体: $agentId');
      
      await _client
          .from('custom_agents')
          .delete()
          .eq('agent_id', agentId);

      debugPrint('✅ 智能体删除成功');
    } catch (e) {
      debugPrint('❌ 删除智能体失败: $e');
      throw Exception('删除智能体失败: $e');
    }
  }

  /// 记录智能体使用
  Future<void> recordAgentUsage(String agentId) async {
    try {
      debugPrint('📊 记录智能体使用: $agentId');
      
      // 使用 RPC 函数原子性地增加使用计数
      await _client
          .rpc('increment_agent_usage', params: {
            'p_agent_id': agentId,
          });

      debugPrint('✅ 智能体使用记录成功');
    } catch (e) {
      debugPrint('❌ 记录智能体使用失败: $e');
    }
  }

  /// 为智能体评分
  Future<void> rateAgent({
    required String agentId,
    required String userId,
    required double rating,
    String? review,
  }) async {
    try {
      debugPrint('⭐ 为智能体评分: $agentId, rating: $rating');
      
      // 检查用户是否已经评分过
      final existingRating = await _client
          .from('agent_ratings')
          .select('rating_id')
          .eq('agent_id', agentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRating != null) {
        // 更新现有评分
        await _client
            .from('agent_ratings')
            .update({
              'rating': rating,
              'review': review,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('rating_id', existingRating['rating_id']);
      } else {
        // 创建新评分
        await _client
            .from('agent_ratings')
            .insert({
              'agent_id': agentId,
              'user_id': userId,
              'rating': rating,
              'review': review,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      // 更新智能体的平均评分
      await _client
          .rpc('update_agent_rating', params: {
            'p_agent_id': agentId,
          });

      debugPrint('✅ 智能体评分成功');
    } catch (e) {
      debugPrint('❌ 智能体评分失败: $e');
      throw Exception('智能体评分失败: $e');
    }
  }

  /// 获取智能体评分列表
  Future<List<Map<String, dynamic>>> getAgentRatings(String agentId) async {
    try {
      debugPrint('📝 获取智能体评分: $agentId');
      
      final response = await _client
          .from('agent_ratings')
          .select('''
            *,
            profiles:user_id (
              nickname,
              avatar_url
            )
          ''')
          .eq('agent_id', agentId)
          .order('created_at', ascending: false);

      final ratings = response as List<Map<String, dynamic>>;
      debugPrint('✅ 获取到 ${ratings.length} 条评分');
      return ratings;
    } catch (e) {
      debugPrint('❌ 获取智能体评分失败: $e');
      return [];
    }
  }

  /// 复制智能体（基于现有智能体创建新的）
  Future<CustomAgent> cloneAgent({
    required String sourceAgentId,
    required String userId,
    String? newName,
  }) async {
    try {
      debugPrint('📋 复制智能体: $sourceAgentId');
      
      // 获取源智能体
      final sourceAgent = await getAgentById(sourceAgentId);
      if (sourceAgent == null) {
        throw Exception('源智能体不存在');
      }

      // 创建复制的智能体
      final clonedName = newName ?? '${sourceAgent.agentName} (副本)';
      final clonedAgent = await createCustomAgent(
        userId: userId,
        agentName: clonedName,
        description: sourceAgent.description,
        systemPrompt: sourceAgent.systemPrompt,
        configuration: sourceAgent.configuration,
        avatarUrl: sourceAgent.avatarUrl,
        capabilities: sourceAgent.capabilities,
        tags: sourceAgent.tags,
        isPublic: false, // 复制的智能体默认为私有
      );

      debugPrint('✅ 智能体复制成功: ${clonedAgent.agentName}');
      return clonedAgent;
    } catch (e) {
      debugPrint('❌ 复制智能体失败: $e');
      throw Exception('复制智能体失败: $e');
    }
  }

  /// 获取智能体分类列表
  Future<List<String>> getAgentCategories() async {
    try {
      debugPrint('📂 获取智能体分类');
      
      final response = await _client
          .rpc('get_agent_categories');

      final categories = (response as List)
          .map((item) => item.toString())
          .toList();

      debugPrint('✅ 获取到 ${categories.length} 个分类');
      return categories;
    } catch (e) {
      debugPrint('❌ 获取智能体分类失败: $e');
      return [];
    }
  }

  /// 获取推荐智能体（基于用户偏好）
  Future<List<CustomAgent>> getRecommendedAgents({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint('🎯 获取推荐智能体: $userId');
      
      final response = await _client
          .rpc('get_recommended_agents', params: {
            'p_user_id': userId,
            'p_limit': limit,
          });

      final agents = (response as List)
          .map((json) => CustomAgent.fromJson(json))
          .toList();

      debugPrint('✅ 获取到 ${agents.length} 个推荐智能体');
      return agents;
    } catch (e) {
      debugPrint('❌ 获取推荐智能体失败: $e');
      return [];
    }
  }

  /// 获取智能体使用统计
  Future<Map<String, dynamic>> getAgentStats(String agentId) async {
    try {
      debugPrint('📊 获取智能体统计: $agentId');
      
      final response = await _client
          .rpc('get_agent_stats', params: {
            'p_agent_id': agentId,
          });

      final stats = response as Map<String, dynamic>;
      debugPrint('✅ 智能体统计获取成功');
      return stats;
    } catch (e) {
      debugPrint('❌ 获取智能体统计失败: $e');
      return {};
    }
  }

  /// 获取用户的智能体使用历史
  Future<List<Map<String, dynamic>>> getUserAgentHistory(String userId) async {
    try {
      debugPrint('📈 获取用户智能体使用历史: $userId');
      
      final response = await _client
          .from('agent_usage_logs')
          .select('''
            *,
            custom_agents (
              agent_name,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .order('used_at', ascending: false)
          .limit(50);

      final history = response as List<Map<String, dynamic>>;
      debugPrint('✅ 获取到 ${history.length} 条使用记录');
      return history;
    } catch (e) {
      debugPrint('❌ 获取使用历史失败: $e');
      return [];
    }
  }

  /// 导出智能体配置
  Future<Map<String, dynamic>> exportAgentConfig(String agentId) async {
    try {
      debugPrint('📤 导出智能体配置: $agentId');
      
      final agent = await getAgentById(agentId);
      if (agent == null) {
        throw Exception('智能体不存在');
      }

      final config = {
        'agent_name': agent.agentName,
        'description': agent.description,
        'system_prompt': agent.systemPrompt,
        'configuration': agent.configuration,
        'capabilities': agent.capabilities,
        'tags': agent.tags,
        'export_time': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      debugPrint('✅ 智能体配置导出成功');
      return config;
    } catch (e) {
      debugPrint('❌ 导出智能体配置失败: $e');
      throw Exception('导出智能体配置失败: $e');
    }
  }

  /// 导入智能体配置
  Future<CustomAgent> importAgentConfig({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    try {
      debugPrint('📥 导入智能体配置');
      
      final agent = await createCustomAgent(
        userId: userId,
        agentName: config['agent_name'] ?? '导入的智能体',
        description: config['description'] ?? '',
        systemPrompt: config['system_prompt'] ?? '',
        configuration: config['configuration'] ?? {},
        capabilities: List<String>.from(config['capabilities'] ?? []),
        tags: List<String>.from(config['tags'] ?? []),
        isPublic: false,
      );

      debugPrint('✅ 智能体配置导入成功: ${agent.agentName}');
      return agent;
    } catch (e) {
      debugPrint('❌ 导入智能体配置失败: $e');
      throw Exception('导入智能体配置失败: $e');
    }
  }
}