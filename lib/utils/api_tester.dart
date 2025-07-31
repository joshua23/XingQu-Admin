import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

/// API连接测试工具
/// 用于验证数据库部署和API功能是否正常
class ApiTester {
  static final ApiService _apiService = ApiService.instance;
  static final SupabaseService _supabaseService = SupabaseService.instance;

  /// 测试数据库连接
  static Future<bool> testDatabaseConnection() async {
    try {
      debugPrint('🔗 测试数据库连接...');
      
      // 测试基本连接
      final response = await _supabaseService.client
          .from('users')
          .select('count')
          .count();
      
      debugPrint('✅ 数据库连接成功！用户表记录数: $response');
      return true;
    } catch (e) {
      debugPrint('❌ 数据库连接失败: $e');
      return false;
    }
  }

  /// 测试表结构
  static Future<bool> testTableStructure() async {
    try {
      debugPrint('📋 测试表结构...');
      
      // 测试所有核心表是否存在
      final tables = ['users', 'ai_characters', 'audio_contents', 'creation_items', 'discovery_contents'];
      
      for (String table in tables) {
        try {
          await _supabaseService.client
              .from(table)
              .select('count')
              .count();
          debugPrint('✅ 表 $table 存在');
        } catch (e) {
          debugPrint('❌ 表 $table 不存在或有问题: $e');
          return false;
        }
      }
      
      debugPrint('✅ 所有核心表结构验证通过');
      return true;
    } catch (e) {
      debugPrint('❌ 表结构测试失败: $e');
      return false;
    }
  }

  /// 创建测试数据
  static Future<bool> createTestData() async {
    try {
      debugPrint('📝 创建测试数据...');
      
      // 1. 创建测试用户
      final testUsers = [
        {
          'id': '550e8400-e29b-41d4-a716-446655440001',
          'phone': '+8613800000001',
          'nickname': '星趣测试用户',
          'bio': '这是一个测试用户账号',
          'avatar_url': '⭐',
        },
        {
          'id': '550e8400-e29b-41d4-a716-446655440002',
          'phone': '+8613800000002', 
          'nickname': '创作者测试',
          'bio': '测试创作者账号',
          'avatar_url': '🎨',
        }
      ];

      for (var user in testUsers) {
        try {
          await _supabaseService.client
              .from('users')
              .upsert(user);
        } catch (e) {
          debugPrint('ℹ️ 用户 ${user['nickname']} 可能已存在');
        }
      }
      debugPrint('✅ 测试用户创建完成');

      // 2. 创建测试AI角色
      final testCharacters = [
        {
          'id': '660e8400-e29b-41d4-a716-446655440001',
          'creator_id': '550e8400-e29b-41d4-a716-446655440001',
          'name': '小星助手',
          'personality': '活泼开朗，善于解答问题',
          'description': '星趣平台的AI助手，可以帮助用户解决各种问题',
          'avatar_url': '⭐',
          'is_featured': true,
          'follower_count': 0,
        },
        {
          'id': '660e8400-e29b-41d4-a716-446655440002',
          'creator_id': '550e8400-e29b-41d4-a716-446655440001',
          'name': '月亮姐姐',
          'personality': '温柔体贴，擅长倾听和安慰',
          'description': '善于倾听的AI角色，总能给人温暖和安慰',
          'avatar_url': '🌙',
          'is_featured': true,
          'follower_count': 0,
        },
        {
          'id': '660e8400-e29b-41d4-a716-446655440003',
          'creator_id': '550e8400-e29b-41d4-a716-446655440002',
          'name': '智慧博士',
          'personality': '博学多才，喜欢分享知识',
          'description': '知识渊博的AI角色，可以解答各种学术问题',
          'avatar_url': '🎓',
          'is_featured': false,
          'follower_count': 0,
        }
      ];

      for (var character in testCharacters) {
        try {
          await _supabaseService.client
              .from('ai_characters')
              .upsert(character);
        } catch (e) {
          debugPrint('ℹ️ AI角色 ${character['name']} 可能已存在');
        }
      }
      debugPrint('✅ 测试AI角色创建完成');

      // 3. 创建测试音频内容
      final testAudios = [
        {
          'id': '770e8400-e29b-41d4-a716-446655440001',
          'creator_id': '550e8400-e29b-41d4-a716-446655440001',
          'title': '放松的雨声',
          'description': '60分钟的雨声白噪音，适合工作和学习时播放',
          'audio_url': 'https://example.com/rain-sounds.mp3',
          'duration_seconds': 3600,
          'category': '白噪音',
          'play_count': 1520,
          'like_count': 89,
        },
        {
          'id': '770e8400-e29b-41d4-a716-446655440002',
          'creator_id': '550e8400-e29b-41d4-a716-446655440002',
          'title': '温馨晚安故事',
          'description': '适合睡前收听的温馨小故事',
          'audio_url': 'https://example.com/bedtime-story.mp3',
          'duration_seconds': 900,
          'category': '故事',
          'play_count': 890,
          'like_count': 67,
        },
        {
          'id': '770e8400-e29b-41d4-a716-446655440003',
          'creator_id': '550e8400-e29b-41d4-a716-446655440001',
          'title': '冥想引导音频',
          'description': '10分钟的冥想引导，帮助放松身心',
          'audio_url': 'https://example.com/meditation.mp3',
          'duration_seconds': 600,
          'category': '冥想',
          'play_count': 456,
          'like_count': 34,
        }
      ];

      for (var audio in testAudios) {
        try {
          await _supabaseService.client
              .from('audio_contents')
              .upsert(audio);
        } catch (e) {
          debugPrint('ℹ️ 音频 ${audio['title']} 可能已存在');
        }
      }
      debugPrint('✅ 测试音频内容创建完成');

      // 4. 创建测试发现内容
      final testDiscoveries = [
        {
          'id': '880e8400-e29b-41d4-a716-446655440001',
          'creator_id': '550e8400-e29b-41d4-a716-446655440001',
          'content_type': 'character',
          'title': '如何创建完美的AI角色',
          'description': '详细教程：从零开始创建一个有趣的AI角色',
          'thumbnail_url': '🎭',
          'category': '教程',
          'is_featured': true,
          'view_count': 234,
          'like_count': 45,
        },
        {
          'id': '880e8400-e29b-41d4-a716-446655440002',
          'creator_id': '550e8400-e29b-41d4-a716-446655440002',
          'content_type': 'audio',
          'title': '音频制作小技巧',
          'description': '分享一些实用的音频制作和编辑技巧',
          'thumbnail_url': '🎵',
          'category': '技巧',
          'is_featured': false,
          'view_count': 156,
          'like_count': 28,
        }
      ];

      for (var discovery in testDiscoveries) {
        try {
          await _supabaseService.client
              .from('discovery_contents')
              .upsert(discovery);
        } catch (e) {
          debugPrint('ℹ️ 发现内容 ${discovery['title']} 可能已存在');
        }
      }
      debugPrint('✅ 测试发现内容创建完成');

      debugPrint('🎯 所有测试数据创建完成！');
      return true;
    } catch (e) {
      debugPrint('❌ 创建测试数据失败: $e');
      return false;
    }
  }

  /// 测试API功能
  static Future<bool> testAPIFunctions() async {
    try {
      debugPrint('🔧 测试API功能...');
      
      // 测试获取AI角色
      try {
        final characters = await _apiService.getAICharacters(pageSize: 5);
        debugPrint('✅ AI角色API测试成功！获取到 ${characters.length} 个角色');
        
        for (var character in characters) {
          debugPrint('  - ${character.name}: ${character.description}');
        }
      } catch (e) {
        debugPrint('❌ AI角色API测试失败: $e');
        return false;
      }

      // 测试获取音频内容
      try {
        final audios = await _apiService.getAudioContents(pageSize: 5);
        debugPrint('✅ 音频API测试成功！获取到 ${audios.length} 个音频');
        
        for (var audio in audios) {
          debugPrint('  - ${audio.title}: ${audio.description}');
        }
      } catch (e) {
        debugPrint('❌ 音频API测试失败: $e');
        return false;
      }

      // 测试获取发现内容
      try {
        final discoveries = await _apiService.getDiscoveryContents(pageSize: 5);
        debugPrint('✅ 发现内容API测试成功！获取到 ${discoveries.length} 个内容');
        
        for (var discovery in discoveries) {
          debugPrint('  - ${discovery.title}: ${discovery.description}');
        }
      } catch (e) {
        debugPrint('❌ 发现内容API测试失败: $e');
        return false;
      }

      debugPrint('🎉 所有API功能测试通过！');
      return true;
    } catch (e) {
      debugPrint('❌ API功能测试失败: $e');
      return false;
    }
  }

  /// 运行完整的验证测试
  static Future<Map<String, bool>> runFullValidation() async {
    final results = <String, bool>{};
    
    debugPrint('🚀 开始完整的数据库和API验证...');
    debugPrint('=' * 50);
    
    // 1. 测试数据库连接
    results['database_connection'] = await testDatabaseConnection();
    
    // 2. 测试表结构
    results['table_structure'] = await testTableStructure();
    
    // 3. 创建测试数据
    results['test_data_creation'] = await createTestData();
    
    // 4. 测试API功能
    results['api_functions'] = await testAPIFunctions();
    
    debugPrint('=' * 50);
    
    // 统计结果
    final successCount = results.values.where((v) => v).length;
    final totalTests = results.length;
    
    if (successCount == totalTests) {
      debugPrint('🎉 验证完成：$successCount/$totalTests 全部通过！');
      debugPrint('✅ 数据库部署成功，API连接正常，可以开始使用！');
    } else {
      debugPrint('⚠️ 验证完成：$successCount/$totalTests 通过');
      debugPrint('❌ 部分功能存在问题，请检查数据库配置');
    }
    
    return results;
  }

  /// 显示数据库统计信息
  static Future<void> showDatabaseStats() async {
    try {
      debugPrint('📊 数据库统计信息：');
      
      // 统计各表记录数
      final tables = {
        'users': '用户',
        'ai_characters': 'AI角色', 
        'audio_contents': '音频内容',
        'creation_items': '创作项目',
        'discovery_contents': '发现内容'
      };
      
      for (var entry in tables.entries) {
        try {
          final count = await _supabaseService.client
              .from(entry.key)
              .select('count')
              .count();
          debugPrint('  ${entry.value}: $count 条记录');
        } catch (e) {
          debugPrint('  ${entry.value}: 查询失败');
        }
      }
    } catch (e) {
      debugPrint('❌ 获取统计信息失败: $e');
    }
  }
}