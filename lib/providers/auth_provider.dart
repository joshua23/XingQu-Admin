import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// 用户状态枚举
enum UserStatus {
  guest,     // 游客模式
  loggedIn,  // 已登录
  loggedOut  // 已登出
}

/// 全局认证Provider，响应式管理登录状态
/// 整合Supabase认证状态和本地存储，支持游客模式
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  UserStatus _userStatus = UserStatus.guest; // 默认为游客模式
  
  final AuthService _authService = AuthService();
  
  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get currentUserId => _currentUser?.id;
  String? get userPhone => _currentUser?.phone;
  UserStatus get userStatus => _userStatus;
  bool get isGuest => _userStatus == UserStatus.guest;

  AuthProvider() {
    _initialize();
  }

  /// 初始化认证状态
  Future<void> _initialize() async {
    // 监听Supabase认证状态变化
    _authService.authStateStream.listen((AuthState state) {
      _handleAuthStateChange(state);
    });
    
    // 加载初始状态
    await _loadInitialState();
  }

  /// 处理Supabase认证状态变化
  void _handleAuthStateChange(AuthState state) {
    debugPrint('🔐 认证状态变化: ${state.event}');
    
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _currentUser = state.session?.user;
        _setUserStatus(UserStatus.loggedIn);
        _loadUserProfile();
        break;
      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _userProfile = null;
        _setUserStatus(UserStatus.guest); // 登出后回到游客模式
        break;
      case AuthChangeEvent.tokenRefreshed:
        // Token刷新，保持当前状态
        break;
      default:
        break;
    }
  }

  /// 加载初始认证状态
  Future<void> _loadInitialState() async {
    try {
      // 检查Supabase当前用户
      _currentUser = _authService.currentUser;
      
      // 检查本地登录状态
      final localLoggedIn = await _authService.isLoggedIn();
      
      // 如果有Supabase用户或本地状态为已登录
      if (_currentUser != null || localLoggedIn) {
        _setUserStatus(UserStatus.loggedIn);
        if (_currentUser != null) {
          await _loadUserProfile();
        }
      } else {
        _setUserStatus(UserStatus.guest); // 默认为游客模式
      }
      
      debugPrint('🔍 初始认证状态加载完成');
      debugPrint('  - Supabase用户: ${_currentUser?.id ?? "无"}');
      debugPrint('  - 本地状态: $localLoggedIn');
      debugPrint('  - 用户状态: $_userStatus');
      debugPrint('  - 是否登录: $_isLoggedIn');
      
    } catch (e) {
      debugPrint('⚠️ 加载初始认证状态失败: $e');
      _setUserStatus(UserStatus.guest);
    }
  }

  /// 加载用户资料
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
      debugPrint('✅ 用户资料加载成功');
    } catch (e) {
      debugPrint('⚠️ 加载用户资料失败: $e');
    }
  }

  /// 登录
  /// [phoneNumber] 手机号
  /// [autoLoadProfile] 是否自动加载用户资料
  /// [loginType] 登录类型（手机号或微信）
  Future<void> login({
    String? phoneNumber, 
    bool autoLoadProfile = true,
    String loginType = 'phone'
  }) async {
    try {
      // 更新本地状态
      if (phoneNumber != null) {
        await _authService.setLoggedIn(phoneNumber);
      }
      
      // 获取当前Supabase用户
      _currentUser = _authService.currentUser;
      
      _setUserStatus(UserStatus.loggedIn);
      
      // 自动加载用户资料
      if (autoLoadProfile && _currentUser != null) {
        await _loadUserProfile();
      }
      
      debugPrint('✅ 用户登录成功 ($loginType): ${_currentUser?.id ?? "本地登录"}');
    } catch (e) {
      debugPrint('❌ 登录状态设置失败: $e');
      rethrow;
    }
  }

  /// 微信登录（特殊处理）
  /// [wechatOpenId] 微信OpenID
  /// [nickname] 微信昵称
  /// [avatarUrl] 微信头像URL
  Future<void> loginWithWeChat({
    required String wechatOpenId,
    String? nickname,
    String? avatarUrl,
  }) async {
    try {
      // 创建基于微信OpenID的本地用户标识
      await _authService.setLoggedIn('wechat_$wechatOpenId');
      
      // 设置用户状态
      _setUserStatus(UserStatus.loggedIn);
      
      // 保存微信用户信息到本地用户资料
      if (nickname != null || avatarUrl != null) {
        _userProfile = {
          'nickname': nickname,
          'avatar_url': avatarUrl,
          'login_type': 'wechat',
          'wechat_openid': wechatOpenId,
          'created_at': DateTime.now().toIso8601String(),
        };
        notifyListeners();
      }
      
      debugPrint('✅ 微信登录成功: $nickname ($wechatOpenId)');
    } catch (e) {
      debugPrint('❌ 微信登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 使用AuthService的完整登出逻辑
      await _authService.signOut();
      
      // 清除本地状态，回到游客模式
      _currentUser = null;
      _userProfile = null;
      _setUserStatus(UserStatus.guest);
      
      debugPrint('✅ 用户登出成功，回到游客模式');
    } catch (e) {
      debugPrint('❌ 登出失败: $e');
      // 即使登出失败，也要清除本地状态
      _currentUser = null;
      _userProfile = null;
      _setUserStatus(UserStatus.guest);
    }
  }

  /// 刷新用户资料
  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
  }

  /// 更新用户资料
  /// [nickname] 昵称
  /// [bio] 个人简介
  /// [avatarUrl] 头像URL
  Future<bool> updateUserProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final success = await _authService.updateUserProfile(
        nickname: nickname,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      
      if (success) {
        // 刷新本地用户资料
        await _loadUserProfile();
        debugPrint('✅ 用户资料更新成功');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ 用户资料更新失败: $e');
      return false;
    }
  }

  /// 检查是否关注了指定用户
  Future<bool> isFollowing(String targetUserId) async {
    return await _authService.isFollowing(targetUserId);
  }

  /// 切换关注状态
  Future<bool> toggleFollow(String targetUserId) async {
    try {
      return await _authService.toggleFollow(targetUserId);
    } catch (e) {
      debugPrint('❌ 切换关注状态失败: $e');
      rethrow;
    }
  }

  /// 检查是否需要登录才能执行某个操作
  /// 游客模式下需要登录的操作：订阅、点赞、评论、关注、创作
  bool requiresAuthentication(String action) {
    if (_userStatus == UserStatus.loggedIn) {
      return false; // 已登录用户不需要额外认证
    }
    
    // 定义需要登录的操作
    const requiredAuthActions = {
      'subscribe', '订阅',
      'like', '点赞', 
      'comment', '评论',
      'follow', '关注',
      'create', '创作',
      'publish', '发布',
      'upload', '上传',
      'edit_profile', '编辑资料',
    };
    
    return requiredAuthActions.contains(action.toLowerCase());
  }

  /// 尝试执行需要认证的操作
  /// 如果是游客且操作需要认证，返回false；否则返回true
  bool canPerformAction(String action) {
    return !requiresAuthentication(action);
  }

  /// 设置用户状态并通知监听者
  void _setUserStatus(UserStatus status) {
    if (_userStatus != status) {
      _userStatus = status;
      _isLoggedIn = (status == UserStatus.loggedIn);
      notifyListeners();
      debugPrint('🔄 用户状态变更为: $status');
    }
  }

  /// 设置登录状态并通知监听者（保持向后兼容）
  void _setLoggedIn(bool loggedIn) {
    _setUserStatus(loggedIn ? UserStatus.loggedIn : UserStatus.guest);
  }
}
