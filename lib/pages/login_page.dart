import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';
import '../services/auth_service.dart';
import 'main_page_refactored.dart';
import 'dart:math' as math;
import '../widgets/starry_background.dart';
import '../widgets/glowing_logo.dart';
import 'wechat_auth_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/sms_service.dart';

/// 登录页面Widget
/// 实现手机号验证码登录和微信登录功能
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// 登录页面状态类
/// 管理表单输入、验证码倒计时、登录状态等
class _LoginPageState extends State<LoginPage> {
  // 表单key，用于验证表单输入
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 文本控制器
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // 状态变量
  bool _isCodeRequested = false; // 是否已请求验证码
  int _countdownSeconds = 60; // 倒计时秒数
  bool _isAgreed = false; // 是否同意用户协议
  String? _errorMessage; // 错误信息

  // 认证服务实例
  final AuthService _authService = AuthService();

  // 短信服务实例
  final AliyunSmsService _smsService = AliyunSmsService();

  // 验证码存储（开发模式下本地存储，生产需服务器端）
  String? _sentCode;
  // 临时验证码（用于测试）
  String? _tempCode;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, // 键盘弹出时自动顶起
      body: StarryBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // 呼吸光环Logo
                const GlowingLogo(size: 120),
                const SizedBox(height: 24),
                // 主副标题
                _buildLoginTitle(),
                const SizedBox(height: 32),
                // 用Form包裹表单区，确保_formKey生效
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: _buildLoginForm(),
                  ),
                ),
                const SizedBox(height: 32),
                // 底部帮助链接
                _buildHelpLinks(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建主副标题，字号、配色、阴影与高保真原型一致。
  Widget _buildLoginTitle() {
    return Column(
      children: [
        Text(
          '星趣', // 修改主标题
          style: AppTextStyles.h1.copyWith(
            fontSize: 36,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '发现有趣的故事，遇见有趣的人',
          style: AppTextStyles.body2.copyWith(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建登录表单区，包含手机号、验证码、协议、按钮、分割线、微信登录。
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null) _buildErrorMessage(),
        // 手机号输入框
        _buildPhoneInput(),
        const SizedBox(height: 18),
        // 验证码输入+获取
        _buildCodeInput(),
        const SizedBox(height: 10),
        // 协议勾选
        _buildAgreementCheckbox(),
        const SizedBox(height: 20),
        // 主登录按钮
        _buildLoginButton(),
        const SizedBox(height: 20),
        // 分割线
        _buildDivider(),
        const SizedBox(height: 10),
        // 微信登录按钮
        _buildWechatLoginButton(),
      ],
    );
  }

  /// 手机号输入框，带icon、圆角、深色背景、品牌色边框。
  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: AppTextStyles.body1,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.phone, color: AppColors.primary),
        hintText: '请输入手机号',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (String? value) {
        // 只需11位数字即可通过
        if (value == null || value.isEmpty) return '请输入手机号';
        if (value.length != 11 || int.tryParse(value) == null)
          return '请输入11位手机号';
        return null;
      },
      onChanged: (value) {
        // 用户开始输入手机号时，清除错误信息
        if (_errorMessage != null && value.isNotEmpty) {
          setState(() { _errorMessage = null; });
        }
      },
    );
  }

  /// 验证码输入框+获取验证码按钮，极简线框风格。
  Widget _buildCodeInput() {
    return Row(
      children: [
        // 验证码输入框
        Expanded(
          child: TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.body1,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.verified_user, color: AppColors.primary),
              hintText: '请输入验证码',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (String? value) {
              // 只需6位数字即可通过
              if (value == null || value.isEmpty) return '请输入验证码';
              if (value.length != 6 || int.tryParse(value) == null)
                return '请输入6位数字验证码';
              return null;
            },
            onChanged: (value) {
              // 用户开始输入验证码时，清除错误信息
              if (_errorMessage != null && value.isNotEmpty) {
                setState(() { _errorMessage = null; });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        // 获取验证码按钮
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: _isCodeRequested ? null : () => _onGetCode(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              minimumSize: const Size(90, 44),
            ),
            child: Text(
              _isCodeRequested ? '$_countdownSeconds s' : '获取验证码',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 协议勾选区，复选框+协议文本横向排列，紧凑。
  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isAgreed,
          onChanged: (bool? value) {
            setState(() {
              _isAgreed = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              // TODO: 跳转协议页面
            },
            child: Text.rich(
              TextSpan(
                text: '我已阅读并同意',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
                children: [
                  TextSpan(
                    text: '《用户协议》',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  /// 主登录按钮，未勾选协议时为灰色，勾选后高亮logo色。
  Widget _buildLoginButton() {
    final bool canLogin = _isAgreed;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canLogin ? () => _onLogin(context) : null,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (!canLogin || states.contains(MaterialState.disabled)) {
              return AppColors.textHint.withOpacity(0.5); // 灰色禁用，透明度0.5，保证可见
            }
            return AppColors.primary; // logo色高亮
          }),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          height: 48,
          child: Text(
            '登录',
            style: AppTextStyles.button.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// 分割线，品牌色20%透明度。
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
            endIndent: 8,
          ),
        ),
        Text('或',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
            indent: 8,
          ),
        ),
      ],
    );
  }

  /// 微信登录按钮，线框风格，icon为微信绿。
  Widget _buildWechatLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          // 跳转到微信授权页
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WeChatAuthPage()),
          );
        },
        icon: Icon(Icons.wechat, color: AppColors.wechat),
        label: Text(
          '微信登录',
          style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.wechat, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      ),
    );
  }

  /// 错误提示，红色小字体。
  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        _errorMessage ?? '',
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }

  /// 底部帮助链接，小字体灰色，居中排列。
  Widget _buildHelpLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: Text('忘记密码',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {},
          child: Text('联系客服',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  /// 获取验证码 - 直接调用 Edge Function 发送 OTP
  /// [context] BuildContext 用于 UI 更新
  Future<void> _onGetCode(BuildContext context) async {
    final String? phone = _phoneController.text;
    debugPrint('📱 尝试发送验证码到: $phone');
    
    // 清除之前的错误信息
    if (_errorMessage != null) {
      setState(() { _errorMessage = null; });
    }
    
    // 只验证手机号，不验证验证码字段
    if (phone == null || phone.isEmpty) {
      debugPrint('❌ 手机号为空');
      setState(() { _errorMessage = '请输入手机号'; });
      return;
    }
    
    // 验证手机号格式
    final phoneError = _validatePhone(phone);
    if (phoneError != null) {
      debugPrint('❌ 手机号格式错误: $phoneError');
      setState(() { _errorMessage = phoneError; });
      return;
    }

    try {
      debugPrint('🚀 直接调用 Edge Function...');
      
      // 生成6位随机验证码
      final String code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // 调用 Edge Function
      final response = await http.post(
        Uri.parse('https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/send-aliyun-sms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w',
        },
        body: jsonEncode({
          'phone': '+86$phone',
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Edge Function 调用成功');
        // 临时存储验证码用于测试
        _tempCode = code;
        
        setState(() {
          _isCodeRequested = true;
          _countdownSeconds = 60;
        });
        _startCountdown();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('验证码已发送'), duration: Duration(seconds: 2)),
          );
        }
      } else {
        throw Exception('Edge Function 返回错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 验证码发送失败: $e');
      setState(() { _errorMessage = '验证码发送失败: $e'; });
    }
  }

  /// 开始倒计时
  /// 获取验证码后的倒计时功能
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
        _startCountdown();
      } else if (mounted) {
        setState(() {
          _isCodeRequested = false;
        });
      }
    });
  }

  /// 执行登录 - 验证 OTP 并登录
  /// [context] BuildContext 用于导航和 UI 更新
  Future<void> _onLogin(BuildContext context) async {
    if (!_isAgreed || !_formKey.currentState!.validate()) return;

    final String? code = _codeController.text;
    final String? phone = _phoneController.text;
    if (code == null || phone == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 临时验证码检查（开发模式）
      if (_tempCode != null && code == _tempCode) {
        debugPrint('✅ 临时验证码验证成功');
        if (context.mounted) Navigator.pop(context);
        
        await Provider.of<AuthProvider>(context, listen: false).login();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPageRefactored()),
          );
        }
        return;
      } else if (_tempCode != null) {
        // 临时验证码验证失败时，重置验证码按钮状态
        if (context.mounted) Navigator.pop(context);
        setState(() { 
          _errorMessage = '验证码错误，请重新获取验证码';
          _isCodeRequested = false;
          _countdownSeconds = 60;
        });
        return;
      }

      // 尝试 Supabase 验证（如果配置正确）
      try {
        final AuthResponse response = await Supabase.instance.client.auth.verifyOTP(
          phone: phone,
          token: code,
          type: OtpType.sms,
        );

        if (context.mounted) Navigator.pop(context);

        if (response.user != null) {
          await Provider.of<AuthProvider>(context, listen: false).login();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainPageRefactored()),
            );
          }
        } else {
          // 验证码无效时，重置验证码按钮状态，允许用户重新获取验证码
          setState(() { 
            _errorMessage = '验证码无效，请重新获取验证码';
            _isCodeRequested = false;
            _countdownSeconds = 60;
          });
        }
      } catch (e) {
        debugPrint('❌ Supabase 验证失败: $e');
        // 验证码验证失败时，重置验证码按钮状态，允许用户重新获取验证码
        setState(() { 
          _errorMessage = '验证码无效或已过期，请重新获取验证码';
          _isCodeRequested = false;
          _countdownSeconds = 60;
        });
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      setState(() { _errorMessage = '登录失败: $e'; });
    }
  }

  /// 验证手机号格式
  /// [value] 输入的手机号
  /// 返回错误信息或null
  String? _validatePhone(String? value) {
    // 只需11位数字即可通过
    if (value == null || value.isEmpty) {
      return '请输入手机号码';
    }
    if (value.length != 11 || int.tryParse(value) == null) {
      return '请输入11位手机号';
    }
    return null;
  }

  /// 验证验证码格式
  /// [value] 输入的验证码
  /// 返回错误信息或null
  String? _validateCode(String? value) {
    // 只需6位数字即可通过
    if (value == null || value.isEmpty) {
      return '请输入验证码';
    }
    if (value.length != 6 || int.tryParse(value) == null) {
      return '请输入6位数字验证码';
    }
    return null;
  }

  /// 清除错误信息
  /// 用户输入时清除之前的错误提示
  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
}

/// 星空背景自定义Painter，绘制大量星星
class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5DFAF).withOpacity(0.22);
    final random = math.Random(202406); // 固定种子，分布一致
    // 画小星星
    for (int i = 0; i < 160; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 1.8 + 0.7;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    // 画五角星
    for (int i = 0; i < 14; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 7 + 4;
      _drawStar(canvas, Offset(x, y), r, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = math.pi / 2 + i * 2 * math.pi / 5;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy - radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final angle2 = angle + math.pi / 5;
      final x2 = center.dx + radius * 0.5 * math.cos(angle2);
      final y2 = center.dy - radius * 0.5 * math.sin(angle2);
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
