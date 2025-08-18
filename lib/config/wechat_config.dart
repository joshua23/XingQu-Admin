/// 微信开放平台配置
class WeChatConfig {
  WeChatConfig._();

  /// 微信应用ID
  static const String appId = 'wxf42ea619f3591510';
  
  /// 微信应用密钥（注意：生产环境中应该放在服务端）
  /// 从环境变量获取，不应硬编码在客户端
  static String get appSecret {
    return const String.fromEnvironment(
      'WECHAT_APP_SECRET',
      defaultValue: '', // 空值，强制使用环境变量
    );
  }
  
  /// iOS Universal Links
  /// 格式：https://your-domain.com/
  /// 需要在微信开放平台配置，并在iOS项目中设置Associated Domains
  /// 注意：这需要你在微信开放平台配置相同的域名
  static const String universalLink = 'https://xinqu.app/';
  
  /// 微信授权scope
  static const String authScope = 'snsapi_userinfo';
  
  /// 微信授权state（防止CSRF攻击）
  static const String authState = 'xinqu_wechat_auth';
  
  /// 获取微信用户信息API
  static const String userInfoUrl = 'https://api.weixin.qq.com/sns/userinfo';
  
  /// 获取微信访问令牌API
  static const String accessTokenUrl = 'https://api.weixin.qq.com/sns/oauth2/access_token';
  
  /// 刷新访问令牌API
  static const String refreshTokenUrl = 'https://api.weixin.qq.com/sns/oauth2/refresh_token';
  
  /// 验证访问令牌API
  static const String validateTokenUrl = 'https://api.weixin.qq.com/sns/auth';
}