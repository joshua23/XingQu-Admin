import 'package:flutter/material.dart';
// import 'package:fluwx/fluwx.dart'; // 暂时注释掉
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/wechat_config.dart';

/// 微信登录服务类
/// 处理微信授权、用户信息获取等功能
class WeChatService {
  static final WeChatService _instance = WeChatService._internal();
  factory WeChatService() => _instance;
  WeChatService._internal();

  bool _isInitialized = false;

  /// 初始化微信SDK
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 临时注释掉，等待正确的API调用方式
      // await registerWxApi(
      //   appId: WeChatConfig.appId,
      //   universalLink: WeChatConfig.universalLink,
      // );

      _isInitialized = true;
      debugPrint('✅ 微信SDK初始化成功（模拟）');
      return true;
    } catch (e) {
      debugPrint('❌ 微信SDK初始化失败: $e');
      return false;
    }
  }

  /// 检查微信是否已安装
  Future<bool> checkWeChatInstalled() async {
    try {
      // 临时返回false，表示未安装，这样可以显示提示信息
      debugPrint('📱 检查微信安装状态（模拟）');
      return false; // 在真机上测试时可以尝试真实检查
    } catch (e) {
      debugPrint('❌ 检查微信安装状态失败: $e');
      return false;
    }
  }

  /// 发起微信授权登录
  Future<WeChatAuthResult> login() async {
    try {
      // 检查初始化状态
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult) {
          return WeChatAuthResult.error('微信SDK初始化失败');
        }
      }

      // 检查微信是否安装
      final isInstalled = await checkWeChatInstalled();
      if (!isInstalled) {
        return WeChatAuthResult.error('请先安装微信应用');
      }

      debugPrint('🚀 开始微信授权登录');
      
      // 发起微信授权（临时模拟）
      debugPrint('🚀 模拟微信授权流程');
      
      // 模拟授权结果
      return WeChatAuthResult.error('微信登录功能需要在真机上测试，模拟器不支持微信SDK');
      
      // 真实的API调用（待修复）
      // final authResult = await sendWeChatAuth(
      //   scope: WeChatConfig.authScope,
      //   state: WeChatConfig.authState,
      // );
      // if (authResult.isSuccessful) {
      //   debugPrint('✅ 微信授权成功');
      //   return WeChatAuthResult.success(authResult.code!);
      // } else {
      //   debugPrint('❌ 微信授权失败: ${authResult.errorCode} - ${authResult.description}');
      //   return WeChatAuthResult.error(authResult.description ?? '微信授权失败');
      // }
    } catch (e) {
      debugPrint('❌ 微信登录异常: $e');
      return WeChatAuthResult.error('微信登录异常: $e');
    }
  }

  /// 通过授权码获取访问令牌
  Future<WeChatTokenResult> getAccessToken(String code) async {
    try {
      final url = '${WeChatConfig.accessTokenUrl}?'
          'appid=${WeChatConfig.appId}&'
          'secret=${WeChatConfig.appSecret}&'
          'code=$code&'
          'grant_type=authorization_code';

      debugPrint('🔄 获取微信访问令牌: $code');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['errcode'] != null) {
          debugPrint('❌ 获取访问令牌失败: ${data['errmsg']}');
          return WeChatTokenResult.error(data['errmsg']);
        }
        
        debugPrint('✅ 成功获取微信访问令牌');
        return WeChatTokenResult.success(
          accessToken: data['access_token'],
          openId: data['openid'],
          scope: data['scope'],
          unionId: data['unionid'],
        );
      } else {
        return WeChatTokenResult.error('网络请求失败');
      }
    } catch (e) {
      debugPrint('❌ 获取访问令牌异常: $e');
      return WeChatTokenResult.error('获取访问令牌异常: $e');
    }
  }

  /// 获取微信用户信息
  Future<WeChatUserResult> getUserInfo(String accessToken, String openId) async {
    try {
      final url = '${WeChatConfig.userInfoUrl}?'
          'access_token=$accessToken&'
          'openid=$openId&'
          'lang=zh_CN';

      debugPrint('🔄 获取微信用户信息');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['errcode'] != null) {
          debugPrint('❌ 获取用户信息失败: ${data['errmsg']}');
          return WeChatUserResult.error(data['errmsg']);
        }
        
        debugPrint('✅ 成功获取微信用户信息: ${data['nickname']}');
        return WeChatUserResult.success(
          openId: data['openid'],
          nickname: data['nickname'],
          sex: data['sex'], // 1为男性，2为女性，0为未知
          province: data['province'],
          city: data['city'],
          country: data['country'],
          headImgUrl: data['headimgurl'],
          unionId: data['unionid'],
        );
      } else {
        return WeChatUserResult.error('网络请求失败');
      }
    } catch (e) {
      debugPrint('❌ 获取用户信息异常: $e');
      return WeChatUserResult.error('获取用户信息异常: $e');
    }
  }

  /// 完整的微信登录流程
  Future<WeChatLoginResult> completeLogin() async {
    try {
      // 1. 发起微信授权
      final authResult = await login();
      if (!authResult.isSuccess) {
        return WeChatLoginResult.error(authResult.errorMessage!);
      }

      // 2. 获取访问令牌
      final tokenResult = await getAccessToken(authResult.code!);
      if (!tokenResult.isSuccess) {
        return WeChatLoginResult.error(tokenResult.errorMessage!);
      }

      // 3. 获取用户信息
      final userResult = await getUserInfo(
        tokenResult.accessToken!,
        tokenResult.openId!,
      );
      if (!userResult.isSuccess) {
        return WeChatLoginResult.error(userResult.errorMessage!);
      }

      debugPrint('🎉 微信登录流程完成');
      return WeChatLoginResult.success(
        token: tokenResult,
        user: userResult,
      );
    } catch (e) {
      debugPrint('❌ 微信登录流程异常: $e');
      return WeChatLoginResult.error('微信登录流程异常: $e');
    }
  }
}

/// 微信授权结果
class WeChatAuthResult {
  final bool isSuccess;
  final String? code;
  final String? errorMessage;

  WeChatAuthResult._({
    required this.isSuccess,
    this.code,
    this.errorMessage,
  });

  factory WeChatAuthResult.success(String code) {
    return WeChatAuthResult._(isSuccess: true, code: code);
  }

  factory WeChatAuthResult.error(String message) {
    return WeChatAuthResult._(isSuccess: false, errorMessage: message);
  }
}

/// 微信访问令牌结果
class WeChatTokenResult {
  final bool isSuccess;
  final String? accessToken;
  final String? openId;
  final String? scope;
  final String? unionId;
  final String? errorMessage;

  WeChatTokenResult._({
    required this.isSuccess,
    this.accessToken,
    this.openId,
    this.scope,
    this.unionId,
    this.errorMessage,
  });

  factory WeChatTokenResult.success({
    required String accessToken,
    required String openId,
    String? scope,
    String? unionId,
  }) {
    return WeChatTokenResult._(
      isSuccess: true,
      accessToken: accessToken,
      openId: openId,
      scope: scope,
      unionId: unionId,
    );
  }

  factory WeChatTokenResult.error(String message) {
    return WeChatTokenResult._(isSuccess: false, errorMessage: message);
  }
}

/// 微信用户信息结果
class WeChatUserResult {
  final bool isSuccess;
  final String? openId;
  final String? nickname;
  final int? sex; // 1男性, 2女性, 0未知
  final String? province;
  final String? city;
  final String? country;
  final String? headImgUrl;
  final String? unionId;
  final String? errorMessage;

  WeChatUserResult._({
    required this.isSuccess,
    this.openId,
    this.nickname,
    this.sex,
    this.province,
    this.city,
    this.country,
    this.headImgUrl,
    this.unionId,
    this.errorMessage,
  });

  factory WeChatUserResult.success({
    required String openId,
    required String nickname,
    int? sex,
    String? province,
    String? city,
    String? country,
    String? headImgUrl,
    String? unionId,
  }) {
    return WeChatUserResult._(
      isSuccess: true,
      openId: openId,
      nickname: nickname,
      sex: sex,
      province: province,
      city: city,
      country: country,
      headImgUrl: headImgUrl,
      unionId: unionId,
    );
  }

  factory WeChatUserResult.error(String message) {
    return WeChatUserResult._(isSuccess: false, errorMessage: message);
  }

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
}

/// 微信登录完整结果
class WeChatLoginResult {
  final bool isSuccess;
  final WeChatTokenResult? token;
  final WeChatUserResult? user;
  final String? errorMessage;

  WeChatLoginResult._({
    required this.isSuccess,
    this.token,
    this.user,
    this.errorMessage,
  });

  factory WeChatLoginResult.success({
    required WeChatTokenResult token,
    required WeChatUserResult user,
  }) {
    return WeChatLoginResult._(
      isSuccess: true,
      token: token,
      user: user,
    );
  }

  factory WeChatLoginResult.error(String message) {
    return WeChatLoginResult._(isSuccess: false, errorMessage: message);
  }
}