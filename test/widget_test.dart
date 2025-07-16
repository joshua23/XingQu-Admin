import 'package:flutter_test/flutter_test.dart';

void main() {
  // 跳过所有测试，原因：依赖网络请求，待mock后再启用
  test('跳过测试', () {}, skip: '跳过依赖网络的测试，待mock后再启用');
}
