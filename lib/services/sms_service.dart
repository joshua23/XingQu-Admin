import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 阿里云短信服务
/// 用于发送手机验证码
/// 注意：需替换为实际的AccessKey、Secret、SignName、TemplateCode
class AliyunSmsService {
  // 阿里云访问密钥（从环境变量获取，确保安全）
  static String get accessKeyId => const String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_ID',
    defaultValue: '',
  );
  
  static String get accessKeySecret => const String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_SECRET', 
    defaultValue: '',
  );
  
  static String get signName => const String.fromEnvironment(
    'ALIYUN_SMS_SIGNATURE',
    defaultValue: '星趣',
  );
  
  static String get templateCode => const String.fromEnvironment(
    'ALIYUN_SMS_TEMPLATE_CODE',
    defaultValue: '',
  );
  static const String smsEndpoint = 'https://dysmsapi.aliyuncs.com';

  /// 发送验证码
  /// [phone] 手机号
  /// [code] 验证码（6位数字）
  /// 返回是否发送成功
  Future<bool> sendVerificationCode(String phone, String code) async {
    try {
      // 生成签名和参数
      final params = {
        'AccessKeyId': accessKeyId,
        'Action': 'SendSms',
        'Format': 'JSON',
        'PhoneNumbers': phone,
        'SignName': signName,
        'TemplateCode': templateCode,
        'TemplateParam': json.encode({'code': code}),
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'SignatureMethod': 'HMAC-SHA1',
        'SignatureNonce': _generateNonce(),
        'SignatureVersion': '1.0',
        'Version': '2017-05-25',
      };

      // 生成签名
      final signature = _generateSignature(params, accessKeySecret);
      params['Signature'] = signature;

      // 发送请求
      final response = await http.post(
        Uri.parse(smsEndpoint),
        body: params,
      );

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['Code'] == 'OK') {
        debugPrint('✅ 验证码发送成功: $phone');
        return true;
      } else {
        debugPrint('❌ 验证码发送失败: ${jsonResponse['Message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 短信发送异常: $e');
      return false;
    }
  }

  /// 生成随机Nonce
  String _generateNonce() {
    return Random().nextInt(999999).toString() + DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 生成阿里云API签名
  String _generateSignature(Map<String, String> params, String secret) {
    // 排序参数
    final sortedKeys = params.keys.toList()..sort();
    String canonicalizedQueryString = '';
    for (String key in sortedKeys) {
      if (params[key]!.isNotEmpty) {
        canonicalizedQueryString += '&' + _percentEncode(key) + '=' + _percentEncode(params[key]!);
      }
    }
    // 去除首个&
    if (canonicalizedQueryString.startsWith('&')) {
      canonicalizedQueryString = canonicalizedQueryString.substring(1);
    }

    // 构建签名字符串
    final stringToSign = 'POST&%2F&' + _percentEncode(canonicalizedQueryString);

    // HMAC-SHA1签名
    final key = utf8.encode(secret + '&');
    final signing = Hmac(sha1, key);
    final digest = signing.convert(utf8.encode(stringToSign));
    return base64.encode(digest.bytes);
  }

  /// URL编码（阿里云特定规则）
  String _percentEncode(String s) {
    return Uri.encodeComponent(s)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }
} 