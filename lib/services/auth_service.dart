import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 认证服务类
/// 处理用户登录、注册、资料管理等认证相关功能
class AuthService {
  // Supabase客户端实例
  final SupabaseClient _client = Supabase.instance.client;

  /// 获取当前用户
  /// 返回当前登录的用户，如果未登录则返回null
  User? get currentUser => _client.auth.currentUser;

  /// 获取当前用户ID
  /// 返回当前登录用户的ID，如果未登录则返回null
  String? get currentUserId => currentUser?.id;

  /// 检查用户是否已登录（优先本地持久化）
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// 本地保存登录状态
  Future<void> setLoggedIn(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('loginPhone', phone);
  }

  /// 本地清除登录状态
  Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('loginPhone');
  }

  /// 发送短信验证码
  /// [phoneNumber] 手机号码
  /// 返回是否发送成功
  Future<bool> sendSmsCode(String phoneNumber) async {
    try {
      // 验证手机号格式
      if (!isValidPhoneNumber(phoneNumber)) {
        throw const AuthException('请输入正确的手机号码');
      }

      // 格式化手机号（添加国家代码）
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      // 发送短信验证码
      await _client.auth.signInWithOtp(
        phone: formattedPhone,
      );

      return true;
    } on AuthException catch (e) {
      debugPrint('发送验证码失败: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('发送验证码异常: $e');
      throw Exception('发送验证码失败，请检查网络连接');
    }
  }

  /// 验证短信验证码并登录（模拟）
  /// [phoneNumber] 手机号码
  /// [code] 验证码
  /// [nickname] 用户昵称（新用户注册时需要）
  /// 返回登录是否成功（开发环境模拟）
  Future<bool> verifyCodeAndSignIn({
    required String phoneNumber,
    required String code,
    String? nickname,
  }) async {
    if (code.length == 6) {
      await setLoggedIn(phoneNumber);
      return true;
    }
    throw const AuthException('请输入6位验证码');
  }

  /// 确保用户资料存在
  /// [user] 认证用户
  /// [nickname] 用户昵称
  Future<void> _ensureUserProfile(User user, String nickname) async {
    try {
      // 检查用户资料是否存在
      final response = await _client
          .from(SupabaseTables.users)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // 创建新用户资料
        await _client.from(SupabaseTables.users).insert({
          'id': user.id,
          'phone': user.phone ?? '',
          'nickname': nickname,
          'avatar_url': null,
          'bio': null,
        });
      }
    } catch (e) {
      // 用户资料创建失败不应该阻止登录
      debugPrint('创建用户资料失败: $e');
    }
  }

  /// 获取用户资料
  /// [userId] 用户ID，如果为null则获取当前用户
  /// 返回用户信息
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) return null;

      final response = await _client
          .from(SupabaseTables.users)
          .select()
          .eq('id', targetUserId)
          .single();

      return response;
    } catch (e) {
      debugPrint('获取用户资料失败: $e');
      return null;
    }
  }

  /// 更新用户资料
  /// [nickname] 用户昵称
  /// [bio] 个人简介
  /// [avatarUrl] 头像URL
  /// 返回是否更新成功
  Future<bool> updateUserProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      if (currentUserId == null) {
        throw const AuthException('用户未登录');
      }

      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      if (updateData.isEmpty) return true;

      await _client
          .from(SupabaseTables.users)
          .update(updateData)
          .eq('id', currentUserId!);

      return true;
    } catch (e) {
      debugPrint('更新用户资料失败: $e');
      return false;
    }
  }

  /// 检查用户是否关注了指定用户
  /// [targetUserId] 目标用户ID
  /// 返回是否已关注
  Future<bool> isFollowing(String targetUserId) async {
    try {
      if (currentUserId == null) return false;

      final response = await _client
          .from(SupabaseTables.follows)
          .select()
          .eq('follower_id', currentUserId!)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('检查关注状态失败: $e');
      return false;
    }
  }

  /// 切换关注状态
  /// [targetUserId] 目标用户ID
  /// 返回新的关注状态
  Future<bool> toggleFollow(String targetUserId) async {
    try {
      if (currentUserId == null) {
        throw const AuthException('用户未登录');
      }

      if (currentUserId == targetUserId) {
        throw const AuthException('无法关注自己');
      }

      final isCurrentlyFollowing = await isFollowing(targetUserId);

      if (isCurrentlyFollowing) {
        // 取消关注
        await _client
            .from(SupabaseTables.follows)
            .delete()
            .eq('follower_id', currentUserId!)
            .eq('following_id', targetUserId);
        return false;
      } else {
        // 添加关注
        await _client.from(SupabaseTables.follows).insert({
          'follower_id': currentUserId!,
          'following_id': targetUserId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('切换关注状态失败: $e');
      rethrow;
    }
  }

  /// 登出
  /// 清除本地会话数据
  Future<void> signOut() async {
    await clearLogin();
  }

  /// 监听认证状态变化
  /// 返回认证状态流
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  /// 格式化手机号码
  /// [phone] 原始手机号
  /// 返回格式化后的手机号（添加国家代码）
  String _formatPhoneNumber(String phone) {
    // 移除所有非数字字符
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 如果是11位中国手机号，添加+86前缀
    if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return '+86$cleanPhone';
    }

    // 如果已经有+86前缀，直接返回
    if (cleanPhone.startsWith('86') && cleanPhone.length == 13) {
      return '+$cleanPhone';
    }

    return phone; // 其他情况返回原始号码
  }

  /// 检查手机号格式是否正确
  /// [phone] 手机号码
  /// 返回是否有效
  bool isValidPhoneNumber(String phone) {
    // 移除所有非数字字符
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 检查是否为11位中国手机号
    if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return RegExp(r'^1[3-9]\d{9}$').hasMatch(cleanPhone);
    }

    return false;
  }
}
