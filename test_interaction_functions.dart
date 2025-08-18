import 'package:supabase_flutter/supabase_flutter.dart';

/// 测试交互功能（点赞、关注、评论）
/// 用于排查首页-精选页的交互问题
Future<void> main() async {
  print('🔍 开始测试交互功能...\n');
  
  // 初始化Supabase
  await Supabase.initialize(
    url: 'https://wqdpqhfqrxvssxifpmvt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w',
  );
  
  final client = Supabase.instance.client;
  
  try {
    // 1. 测试匿名登录
    print('1️⃣ 测试匿名登录...');
    final authResponse = await client.auth.signInAnonymously();
    final userId = authResponse.session?.user.id;
    print('✅ 登录成功，用户ID: $userId\n');
    
    if (userId == null) {
      print('❌ 无法获取用户ID');
      return;
    }
    
    // 2. 检查表是否存在
    print('2️⃣ 检查数据库表...');
    await _checkTableExists(client, 'likes');
    await _checkTableExists(client, 'character_follows');
    await _checkTableExists(client, 'comments');
    await _checkTableExists(client, 'ai_characters');
    print('');
    
    // 3. 获取或创建测试角色
    print('3️⃣ 获取测试角色...');
    String? characterId = await _getOrCreateTestCharacter(client);
    if (characterId == null) {
      print('❌ 无法获取测试角色');
      return;
    }
    print('✅ 测试角色ID: $characterId\n');
    
    // 4. 测试点赞功能
    print('4️⃣ 测试点赞功能...');
    await _testLikeFunction(client, userId, characterId);
    print('');
    
    // 5. 测试关注功能
    print('5️⃣ 测试关注功能...');
    await _testFollowFunction(client, userId, characterId);
    print('');
    
    // 6. 测试评论功能
    print('6️⃣ 测试评论功能...');
    await _testCommentFunction(client, userId, characterId);
    print('');
    
    // 7. 检查数据是否成功写入
    print('7️⃣ 验证数据写入...');
    await _verifyDataInDatabase(client, userId, characterId);
    
    print('\n✅ 测试完成！');
    
  } catch (e) {
    print('❌ 测试失败: $e');
    print('错误详情: ${e.toString()}');
  }
}

/// 检查表是否存在
Future<void> _checkTableExists(SupabaseClient client, String tableName) async {
  try {
    final result = await client.from(tableName).select('id').limit(1);
    print('  ✅ 表 $tableName 存在');
  } catch (e) {
    print('  ❌ 表 $tableName 不存在或无法访问: $e');
  }
}

/// 获取或创建测试角色
Future<String?> _getOrCreateTestCharacter(SupabaseClient client) async {
  try {
    // 先尝试查找现有的测试角色
    var result = await client
        .from('ai_characters')
        .select('id')
        .eq('name', '寂文泽')
        .limit(1);
    
    if (result.isNotEmpty) {
      return result[0]['id'];
    }
    
    // 如果不存在，创建一个测试角色
    print('  创建测试角色...');
    final insertResult = await client
        .from('ai_characters')
        .insert({
          'name': '寂文泽',
          'description': '测试角色 - 21岁，有占有欲，霸道，只对你撒娇',
          'personality': '霸道总裁',
          'avatar_url': 'https://example.com/avatar.jpg',
        })
        .select('id');
    
    if (insertResult.isNotEmpty) {
      return insertResult[0]['id'];
    }
    
    return null;
  } catch (e) {
    print('  ❌ 获取/创建角色失败: $e');
    
    // 如果创建失败，尝试获取任意一个角色进行测试
    try {
      final anyCharacter = await client
          .from('ai_characters')
          .select('id, name')
          .limit(1);
      
      if (anyCharacter.isNotEmpty) {
        print('  使用现有角色: ${anyCharacter[0]['name']}');
        return anyCharacter[0]['id'];
      }
    } catch (e2) {
      print('  ❌ 无法获取任何角色: $e2');
    }
    
    return null;
  }
}

/// 测试点赞功能
Future<void> _testLikeFunction(SupabaseClient client, String userId, String characterId) async {
  try {
    // 先删除可能存在的旧记录
    await client
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', 'character')
        .eq('target_id', characterId);
    
    print('  添加点赞...');
    await client.from('likes').insert({
      'user_id': userId,
      'target_type': 'character',
      'target_id': characterId,
    });
    print('  ✅ 点赞成功');
    
    // 检查是否点赞
    final checkResult = await client
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('target_type', 'character')
        .eq('target_id', characterId);
    
    if (checkResult.isNotEmpty) {
      print('  ✅ 验证：点赞记录存在');
    } else {
      print('  ❌ 验证：点赞记录不存在');
    }
    
    // 取消点赞
    print('  取消点赞...');
    await client
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', 'character')
        .eq('target_id', characterId);
    print('  ✅ 取消点赞成功');
    
  } catch (e) {
    print('  ❌ 点赞测试失败: $e');
  }
}

/// 测试关注功能
Future<void> _testFollowFunction(SupabaseClient client, String userId, String characterId) async {
  try {
    // 先删除可能存在的旧记录
    await client
        .from('character_follows')
        .delete()
        .eq('user_id', userId)
        .eq('character_id', characterId);
    
    print('  添加关注...');
    await client.from('character_follows').insert({
      'user_id': userId,
      'character_id': characterId,
    });
    print('  ✅ 关注成功');
    
    // 检查是否关注
    final checkResult = await client
        .from('character_follows')
        .select()
        .eq('user_id', userId)
        .eq('character_id', characterId);
    
    if (checkResult.isNotEmpty) {
      print('  ✅ 验证：关注记录存在');
    } else {
      print('  ❌ 验证：关注记录不存在');
    }
    
    // 取消关注
    print('  取消关注...');
    await client
        .from('character_follows')
        .delete()
        .eq('user_id', userId)
        .eq('character_id', characterId);
    print('  ✅ 取消关注成功');
    
  } catch (e) {
    print('  ❌ 关注测试失败: $e');
  }
}

/// 测试评论功能
Future<void> _testCommentFunction(SupabaseClient client, String userId, String characterId) async {
  try {
    print('  添加评论...');
    final result = await client.from('comments').insert({
      'user_id': userId,
      'target_type': 'character',
      'target_id': characterId,
      'content': '测试评论 - ${DateTime.now().toIso8601String()}',
    }).select('id');
    
    if (result.isNotEmpty) {
      final commentId = result[0]['id'];
      print('  ✅ 评论成功，ID: $commentId');
      
      // 删除测试评论
      await client.from('comments').delete().eq('id', commentId);
      print('  ✅ 测试评论已清理');
    }
    
  } catch (e) {
    print('  ❌ 评论测试失败: $e');
  }
}

/// 验证数据是否成功写入数据库
Future<void> _verifyDataInDatabase(SupabaseClient client, String userId, String characterId) async {
  try {
    // 重新添加数据以便验证
    print('  重新添加测试数据...');
    
    // 添加点赞
    await client.from('likes').insert({
      'user_id': userId,
      'target_type': 'character',
      'target_id': characterId,
    }).onError((error, stackTrace) => null); // 忽略重复错误
    
    // 添加关注
    await client.from('character_follows').insert({
      'user_id': userId,
      'character_id': characterId,
    }).onError((error, stackTrace) => null); // 忽略重复错误
    
    // 添加评论
    await client.from('comments').insert({
      'user_id': userId,
      'target_type': 'character',
      'target_id': characterId,
      'content': '验证测试评论',
    });
    
    // 验证数据
    print('  验证数据库中的数据...');
    
    final likes = await client
        .from('likes')
        .select('created_at')
        .eq('user_id', userId)
        .eq('target_id', characterId);
    print('  点赞记录数: ${likes.length}');
    
    final follows = await client
        .from('character_follows')
        .select('created_at')
        .eq('user_id', userId)
        .eq('character_id', characterId);
    print('  关注记录数: ${follows.length}');
    
    final comments = await client
        .from('comments')
        .select('id, content, created_at')
        .eq('user_id', userId)
        .eq('target_id', characterId)
        .order('created_at', ascending: false)
        .limit(5);
    print('  评论记录数: ${comments.length}');
    
    if (likes.isNotEmpty && follows.isNotEmpty && comments.isNotEmpty) {
      print('  ✅ 所有交互数据都已成功写入数据库');
    } else {
      print('  ⚠️ 部分数据可能未成功写入');
    }
    
  } catch (e) {
    print('  ❌ 数据验证失败: $e');
  }
}