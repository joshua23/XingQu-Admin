import 'package:flutter/material.dart';
import 'dart:math';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';

/// 分析测试页面
/// 用于测试移动端数据上报功能
class AnalyticsTestPage extends StatefulWidget {
  const AnalyticsTestPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsTestPage> createState() => _AnalyticsTestPageState();
}

class _AnalyticsTestPageState extends State<AnalyticsTestPage> {
  final AnalyticsService _analytics = AnalyticsService.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  
  int _eventCounter = 0;
  bool _isRunningTest = false;
  String _testStatus = '准备就绪';
  
  @override
  void initState() {
    super.initState();
    // 记录页面访问
    Analytics.page('analytics_test_page');
  }
  
  /// 发送测试用户活动
  Future<void> _sendTestUserActivity() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送用户活动事件...';
    });
    
    final activities = [
      'button_click',
      'page_scroll',
      'content_view',
      'menu_open',
      'search_action'
    ];
    
    final randomActivity = activities[Random().nextInt(activities.length)];
    
    await Analytics.event(randomActivity, {
      'screen': 'analytics_test',
      'test_number': _eventCounter,
      'random_value': Random().nextInt(100),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    setState(() {
      _testStatus = '✅ 用户活动事件已发送: $randomActivity';
    });
  }
  
  /// 发送测试AI角色交互
  Future<void> _sendTestCharacterInteraction() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送AI角色交互...';
    });
    
    final characterIds = ['char_001', 'char_002', 'char_003'];
    final actions = ['chat_start', 'chat_message', 'follow', 'like'];
    
    final randomCharacter = characterIds[Random().nextInt(characterIds.length)];
    final randomAction = actions[Random().nextInt(actions.length)];
    
    await Analytics.character(randomCharacter, randomAction, {
      'test_interaction': true,
      'message_count': Random().nextInt(10) + 1,
      'session_duration': Random().nextInt(300) + 30,
    });
    
    setState(() {
      _testStatus = '✅ AI角色交互已发送: $randomAction -> $randomCharacter';
    });
  }
  
  /// 发送测试音频播放
  Future<void> _sendTestAudioPlay() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送音频播放事件...';
    });
    
    final audioIds = ['audio_001', 'audio_002', 'audio_003'];
    final randomAudioId = audioIds[Random().nextInt(audioIds.length)];
    final duration = Random().nextInt(300) + 60; // 1-5分钟
    final position = Random().nextInt(duration);
    final completed = position > duration * 0.8;
    
    await Analytics.audio(randomAudioId, duration, position, completed);
    
    setState(() {
      _testStatus = '✅ 音频播放事件已发送: $randomAudioId (${position}s/${duration}s)';
    });
  }
  
  /// 发送测试社交互动
  Future<void> _sendTestSocialInteraction() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送社交互动事件...';
    });
    
    final actions = ['like', 'comment', 'follow', 'share'];
    final targetTypes = ['character', 'audio', 'creation'];
    final targetIds = ['target_001', 'target_002', 'target_003'];
    
    final randomAction = actions[Random().nextInt(actions.length)];
    final randomTargetType = targetTypes[Random().nextInt(targetTypes.length)];
    final randomTargetId = targetIds[Random().nextInt(targetIds.length)];
    
    await Analytics.social(randomAction, randomTargetType, randomTargetId, {
      'test_social': true,
      'engagement_score': Random().nextDouble() * 10,
    });
    
    setState(() {
      _testStatus = '✅ 社交互动已发送: $randomAction $randomTargetType';
    });
  }
  
  /// 发送测试创作活动
  Future<void> _sendTestContentCreation() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送创作活动事件...';
    });
    
    final contentTypes = ['ai_character', 'audio_content', 'story'];
    final randomContentType = contentTypes[Random().nextInt(contentTypes.length)];
    
    await Analytics.event('content_create', {
      'content_type': randomContentType,
      'content_id': 'test_content_${Random().nextInt(1000)}',
      'title': '测试创作 #$_eventCounter',
      'tags': ['测试', '分析', randomContentType],
      'is_public': Random().nextBool(),
      'creation_time': Random().nextInt(3600) + 300, // 5分钟到1小时
    });
    
    setState(() {
      _testStatus = '✅ 创作活动已发送: $randomContentType';
    });
  }
  
  /// 发送测试会员订阅
  Future<void> _sendTestSubscription() async {
    setState(() {
      _eventCounter++;
      _testStatus = '发送会员订阅事件...';
    });
    
    final planTypes = ['basic', 'premium', 'lifetime'];
    final randomPlan = planTypes[Random().nextInt(planTypes.length)];
    final amounts = {'basic': 9.9, 'premium': 29.9, 'lifetime': 199.9};
    
    await _analytics.trackSubscription(
      planId: '${randomPlan}_plan_001',
      planType: randomPlan,
      action: 'subscribe',
      amount: amounts[randomPlan],
    );
    
    setState(() {
      _testStatus = '✅ 会员订阅已发送: $randomPlan (¥${amounts[randomPlan]})';
    });
  }
  
  /// 运行自动化测试
  Future<void> _runAutomatedTest() async {
    if (_isRunningTest) return;
    
    setState(() {
      _isRunningTest = true;
      _testStatus = '开始自动化测试...';
    });
    
    try {
      final testActions = [
        _sendTestUserActivity,
        _sendTestCharacterInteraction,
        _sendTestAudioPlay,
        _sendTestSocialInteraction,
        _sendTestContentCreation,
        _sendTestSubscription,
      ];
      
      // 随机执行10个测试动作
      for (int i = 0; i < 10; i++) {
        final randomAction = testActions[Random().nextInt(testActions.length)];
        await randomAction();
        
        // 等待1-3秒之间的随机时间
        await Future.delayed(Duration(seconds: Random().nextInt(3) + 1));
      }
      
      setState(() {
        _testStatus = '🎉 自动化测试完成！发送了10个随机事件';
      });
      
    } catch (e) {
      setState(() {
        _testStatus = '❌ 自动化测试失败: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }
  
  /// 发送心跳测试
  Future<void> _sendHeartbeat() async {
    setState(() {
      _testStatus = '发送心跳信号...';
    });
    
    await _analytics.sendHeartbeat();
    
    setState(() {
      _testStatus = '💓 心跳信号已发送';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('移动端数据分析测试'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '数据分析测试',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '用户ID: ${_supabase.currentUserId ?? '未登录'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '已发送: $_eventCounter',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testStatus,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 单个测试按钮
            const Text(
              '单个测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildTestButton(
                  icon: Icons.touch_app,
                  title: '用户活动',
                  subtitle: '按钮点击、页面访问',
                  color: Colors.blue,
                  onTap: _sendTestUserActivity,
                ),
                _buildTestButton(
                  icon: Icons.smart_toy,
                  title: 'AI角色交互',
                  subtitle: '对话、关注、点赞',
                  color: Colors.purple,
                  onTap: _sendTestCharacterInteraction,
                ),
                _buildTestButton(
                  icon: Icons.play_circle,
                  title: '音频播放',
                  subtitle: '播放进度、完成状态',
                  color: Colors.orange,
                  onTap: _sendTestAudioPlay,
                ),
                _buildTestButton(
                  icon: Icons.favorite,
                  title: '社交互动',
                  subtitle: '点赞、评论、分享',
                  color: Colors.red,
                  onTap: _sendTestSocialInteraction,
                ),
                _buildTestButton(
                  icon: Icons.create,
                  title: '创作活动',
                  subtitle: '内容创建、发布',
                  color: Colors.teal,
                  onTap: _sendTestContentCreation,
                ),
                _buildTestButton(
                  icon: Icons.star,
                  title: '会员订阅',
                  subtitle: '购买、升级计划',
                  color: Colors.amber,
                  onTap: _sendTestSubscription,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 批量测试
            const Text(
              '批量测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isRunningTest ? null : _runAutomatedTest,
              icon: _isRunningTest 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
              label: Text(_isRunningTest ? '测试运行中...' : '运行自动化测试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _sendHeartbeat,
              icon: const Icon(Icons.favorite_border),
              label: const Text('发送心跳信号'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 说明文档
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. 点击上方按钮发送测试数据到后台系统\n'
                    '2. 打开Web后台管理系统的"移动端监控"页面\n'
                    '3. 观察数据是否实时显示在后台系统中\n'
                    '4. 运行自动化测试可以生成更多样化的测试数据',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}