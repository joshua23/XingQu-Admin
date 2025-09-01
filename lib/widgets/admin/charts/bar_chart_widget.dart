import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 交互式柱状图组件
/// 用于展示时间序列数据和对比分析
class InteractiveBarChart extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;
  final Color primaryColor;
  final Color hoverColor;

  const InteractiveBarChart({
    super.key,
    required this.data,
    required this.title,
    this.xAxisLabel = '',
    this.yAxisLabel = '',
    this.primaryColor = const Color(0xFFFFD700),
    this.hoverColor = const Color(0xFF4FC3F7),
  });

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _hoveredIndex = -1;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
        height: 350,
        child: Card(
          child: const Center(
            child: Text(
              '暂无数据',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_selectedKey != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.primaryColor, width: 1),
                    ),
                    child: Text(
                      '$_selectedKey: ${widget.data[_selectedKey]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BarChartPainter(
                      data: widget.data,
                      animationValue: _animation.value,
                      hoveredIndex: _hoveredIndex,
                      primaryColor: widget.primaryColor,
                      hoverColor: widget.hoverColor,
                      xAxisLabel: widget.xAxisLabel,
                      yAxisLabel: widget.yAxisLabel,
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        _handleTap(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _handleHover(details.localPosition);
                      },
                      child: MouseRegion(
                        onHover: (event) {
                          _handleHover(event.localPosition);
                        },
                        onExit: (_) {
                          setState(() {
                            _hoveredIndex = -1;
                          });
                        },
                        child: Container(),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.xAxisLabel.isNotEmpty || widget.yAxisLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.yAxisLabel.isNotEmpty) ...[
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          widget.yAxisLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                    if (widget.xAxisLabel.isNotEmpty)
                      Text(
                        widget.xAxisLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset localPosition) {
    final entries = widget.data.entries.toList();
    if (entries.isEmpty) return;

    const padding = 60.0;
    final chartWidth = 280 - padding * 2;
    final barWidth = chartWidth / entries.length;
    
    final index = ((localPosition.dx - padding) / barWidth).floor();
    
    if (index >= 0 && index < entries.length) {
      setState(() {
        final key = entries[index].key;
        _selectedKey = _selectedKey == key ? null : key;
      });
    }
  }

  void _handleHover(Offset localPosition) {
    final entries = widget.data.entries.toList();
    if (entries.isEmpty) return;

    const padding = 60.0;
    final chartWidth = 280 - padding * 2;
    final barWidth = chartWidth / entries.length;
    
    final index = ((localPosition.dx - padding) / barWidth).floor();
    
    if (index >= 0 && index < entries.length && index != _hoveredIndex) {
      setState(() {
        _hoveredIndex = index;
      });
    } else if (index < 0 || index >= entries.length) {
      setState(() {
        _hoveredIndex = -1;
      });
    }
  }
}

class BarChartPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final double animationValue;
  final int hoveredIndex;
  final Color primaryColor;
  final Color hoverColor;
  final String xAxisLabel;
  final String yAxisLabel;

  BarChartPainter({
    required this.data,
    required this.animationValue,
    required this.hoveredIndex,
    required this.primaryColor,
    required this.hoverColor,
    required this.xAxisLabel,
    required this.yAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final entries = data.entries.toList();
    if (entries.isEmpty) return;

    const padding = 60.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    // 找到最大值用于缩放
    final maxValue = entries.map((e) => e.value as int).reduce(math.max).toDouble();
    if (maxValue == 0) return;
    
    final barWidth = chartWidth / entries.length * 0.8;
    final barSpacing = chartWidth / entries.length * 0.2;
    
    // 绘制坐标轴
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;
    
    // Y轴
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    
    // X轴
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    
    // 绘制Y轴刻度线和标签
    for (int i = 0; i <= 5; i++) {
      final y = size.height - padding - (chartHeight / 5 * i);
      final value = (maxValue / 5 * i).toInt();
      
      // 刻度线
      canvas.drawLine(
        Offset(padding - 5, y),
        Offset(padding, y),
        axisPaint,
      );
      
      // 网格线
      if (i > 0) {
        final gridPaint = Paint()
          ..color = Colors.grey[200]!
          ..strokeWidth = 0.5;
        
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          gridPaint,
        );
      }
      
      // Y轴标签
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
    
    // 绘制柱状图
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final value = entry.value as int;
      final barHeight = (value / maxValue) * chartHeight * animationValue;
      
      final x = padding + (chartWidth / entries.length) * i + barSpacing / 2;
      final y = size.height - padding - barHeight;
      
      // 柱子颜色
      Color barColor = primaryColor;
      if (hoveredIndex == i) {
        barColor = hoverColor;
      }
      
      // 绘制柱子
      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;
      
      // 添加渐变效果
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          barColor.withOpacity(0.8),
          barColor,
        ],
      );
      
      barPaint.shader = gradient.createShader(
        Rect.fromLTWH(x, y, barWidth, barHeight),
      );
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      
      canvas.drawRRect(rect, barPaint);
      
      // 绘制柱子边框
      final borderPaint = Paint()
        ..color = barColor.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawRRect(rect, borderPaint);
      
      // X轴标签
      final labelPainter = TextPainter(
        text: TextSpan(
          text: entry.key.length > 8 
              ? '${entry.key.substring(0, 6)}..' 
              : entry.key,
          style: TextStyle(
            color: hoveredIndex == i ? Colors.black87 : Colors.grey[600],
            fontSize: 10,
            fontWeight: hoveredIndex == i ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      labelPainter.layout(maxWidth: barWidth + barSpacing);
      labelPainter.paint(
        canvas,
        Offset(
          x + (barWidth - labelPainter.width) / 2,
          size.height - padding + 8,
        ),
      );
      
      // 悬停时显示数值
      if (hoveredIndex == i && animationValue > 0.8) {
        final valuePainter = TextPainter(
          text: TextSpan(
            text: value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        valuePainter.layout();
        
        // 绘制背景
        final valueRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barWidth / 2, y - 20),
            width: valuePainter.width + 12,
            height: valuePainter.height + 8,
          ),
          const Radius.circular(6),
        );
        
        canvas.drawRRect(
          valueRect,
          Paint()..color = Colors.black.withOpacity(0.8),
        );
        
        valuePainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - valuePainter.width / 2,
            y - 24,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.hoveredIndex != hoveredIndex;
  }
}