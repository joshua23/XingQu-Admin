import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 交互式饼图组件
/// 用于展示数据分布和比例
class InteractivePieChart extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  final List<Color> colors;

  const InteractivePieChart({
    super.key,
    required this.data,
    required this.title,
    this.colors = const [
      Color(0xFFFFD700), // 金色
      Color(0xFF4FC3F7), // 蓝色
      Color(0xFF81C784), // 绿色
      Color(0xFFFFB74D), // 橙色
      Color(0xFFBA68C8), // 紫色
      Color(0xFFE57373), // 红色
    ],
  });

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 300,
        child: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  // 饼图
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PieChartPainter(
                            data: widget.data,
                            colors: widget.colors,
                            animationValue: _animation.value,
                            selectedIndex: _selectedIndex,
                          ),
                          child: GestureDetector(
                            onTapDown: (details) {
                              _handleTap(details.localPosition);
                            },
                            child: Container(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 图例
                  Expanded(
                    flex: 1,
                    child: _buildLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final entries = widget.data.entries.toList();
    final total = entries.fold(0, (sum, entry) => sum + (entry.value as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final dataEntry = entry.value;
        final value = dataEntry.value as int;
        final percentage = total > 0 ? (value / total * 100) : 0.0;
        final color = widget.colors[index % widget.colors.length];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = _selectedIndex == index ? -1 : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedIndex == index 
                  ? color.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: _selectedIndex == index
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataEntry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$value (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: _selectedIndex == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleTap(Offset localPosition) {
    final center = Offset(125, 125); // 假设饼图中心位置
    final distance = (localPosition - center).distance;
    
    if (distance > 100) return; // 点击在饼图外
    
    final angle = math.atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
    final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;
    
    final entries = widget.data.entries.toList();
    final total = entries.fold(0, (sum, entry) => sum + (entry.value as int));
    
    double currentAngle = -math.pi / 2; // 从12点钟方向开始
    for (int i = 0; i < entries.length; i++) {
      final value = entries[i].value as int;
      final sweepAngle = (value / total) * 2 * math.pi;
      
      if (normalizedAngle >= currentAngle && normalizedAngle <= currentAngle + sweepAngle) {
        setState(() {
          _selectedIndex = _selectedIndex == i ? -1 : i;
        });
        break;
      }
      currentAngle += sweepAngle;
    }
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final List<Color> colors;
  final double animationValue;
  final int selectedIndex;

  PieChartPainter({
    required this.data,
    required this.colors,
    required this.animationValue,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    final entries = data.entries.toList();
    final total = entries.fold(0, (sum, entry) => sum + (entry.value as int));
    
    if (total == 0) return;
    
    double startAngle = -math.pi / 2; // 从12点钟方向开始
    
    for (int i = 0; i < entries.length; i++) {
      final value = entries[i].value as int;
      final sweepAngle = (value / total) * 2 * math.pi * animationValue;
      final color = colors[i % colors.length];
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      // 如果选中，增加阴影效果
      if (selectedIndex == i) {
        final shadowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius + 5),
          startAngle,
          sweepAngle,
          true,
          shadowPaint,
        );
      }
      
      // 绘制扇形
      canvas.drawArc(
        Rect.fromCircle(
          center: center, 
          radius: selectedIndex == i ? radius + 3 : radius
        ),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(
          center: center, 
          radius: selectedIndex == i ? radius + 3 : radius
        ),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // 绘制标签（如果选中）
      if (selectedIndex == i && animationValue > 0.8) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.7;
        final labelPosition = Offset(
          center.dx + math.cos(labelAngle) * labelRadius,
          center.dy + math.sin(labelAngle) * labelRadius,
        );
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPosition - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.selectedIndex != selectedIndex;
  }
}