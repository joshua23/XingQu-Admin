import 'package:flutter/material.dart';
import 'dart:math';

/// 模拟微信登录服务
/// 在开发阶段提供完整的微信登录流程模拟
class MockWeChatService {
  static final MockWeChatService _instance = MockWeChatService._internal();
  factory MockWeChatService() => _instance;
  MockWeChatService._internal();

  /// 模拟微信用户数据库
  static final List<MockWeChatUser> _mockUsers = [
    MockWeChatUser(
      openId: 'mock_wx_001',
      nickname: '星趣小助手',
      avatarUrl: 'https://img.icons8.com/color/96/user-female-circle.png',
      sex: 2,
      province: '广东省',
      city: '深圳市',
      country: '中国',
    ),
    MockWeChatUser(
      openId: 'mock_wx_002', 
      nickname: 'AI创作者',
      avatarUrl: 'https://img.icons8.com/color/96/user-male-circle.png',
      sex: 1,
      province: '北京市',
      city: '北京市',
      country: '中国',
    ),
    MockWeChatUser(
      openId: 'mock_wx_003',
      nickname: '故事分享家',
      avatarUrl: 'https://img.icons8.com/color/96/user-female-circle--v2.png',
      sex: 2,
      province: '上海市', 
      city: '上海市',
      country: '中国',
    ),
    MockWeChatUser(
      openId: 'mock_wx_004',
      nickname: '内容探索者',
      avatarUrl: 'https://img.icons8.com/color/96/user-male-circle--v2.png',
      sex: 1,
      province: '浙江省',
      city: '杭州市',
      country: '中国',
    ),
  ];

  /// 初始化模拟微信SDK
  Future<bool> initialize() async {
    debugPrint('✅ 模拟微信SDK初始化成功');
    return true;
  }

  /// 模拟检查微信是否安装
  Future<bool> checkWeChatInstalled() async {
    debugPrint('📱 模拟检查微信安装状态 - 已安装');
    return true;
  }

  /// 模拟微信授权登录流程
  Future<MockWeChatLoginResult> completeLogin() async {
    try {
      debugPrint('🚀 开始模拟微信登录流程');

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 1500));

      // 随机选择一个模拟用户
      final random = Random();
      final selectedUser = _mockUsers[random.nextInt(_mockUsers.length)];

      debugPrint('✅ 模拟微信登录成功: ${selectedUser.nickname}');

      return MockWeChatLoginResult.success(
        user: selectedUser,
        accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('❌ 模拟微信登录失败: $e');
      return MockWeChatLoginResult.error('模拟登录失败: $e');
    }
  }

  /// 获取所有模拟用户（用于开发测试）
  List<MockWeChatUser> getAllMockUsers() {
    return List.from(_mockUsers);
  }

  /// 通过openId获取指定用户（用于测试特定用户）
  Future<MockWeChatLoginResult> loginWithSpecificUser(String openId) async {
    try {
      debugPrint('🎯 使用指定用户登录: $openId');
      
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 800));

      final user = _mockUsers.firstWhere(
        (u) => u.openId == openId,
        orElse: () => _mockUsers.first,
      );

      debugPrint('✅ 指定用户登录成功: ${user.nickname}');

      return MockWeChatLoginResult.success(
        user: user,
        accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('❌ 指定用户登录失败: $e');
      return MockWeChatLoginResult.error('登录失败: $e');
    }
  }
}

/// 模拟微信用户数据
class MockWeChatUser {
  final String openId;
  final String nickname;
  final String avatarUrl;
  final int sex; // 1男性, 2女性, 0未知
  final String province;
  final String city;
  final String country;

  MockWeChatUser({
    required this.openId,
    required this.nickname,
    required this.avatarUrl,
    required this.sex,
    required this.province,
    required this.city,
    required this.country,
  });

  /// 获取性别字符串
  String get genderString {
    switch (sex) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }

  /// 获取地区字符串
  String get locationString {
    if (province == city) {
      return '$province $country';
    }
    return '$province $city $country';
  }

  @override
  String toString() {
    return 'MockWeChatUser{nickname: $nickname, openId: $openId, location: $locationString}';
  }
}

/// 模拟微信登录结果
class MockWeChatLoginResult {
  final bool isSuccess;
  final MockWeChatUser? user;
  final String? accessToken;
  final String? errorMessage;

  MockWeChatLoginResult._({
    required this.isSuccess,
    this.user,
    this.accessToken,
    this.errorMessage,
  });

  factory MockWeChatLoginResult.success({
    required MockWeChatUser user,
    required String accessToken,
  }) {
    return MockWeChatLoginResult._(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
    );
  }

  factory MockWeChatLoginResult.error(String message) {
    return MockWeChatLoginResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}