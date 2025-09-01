import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 交互式折线图组件
/// 用于展示时间序列数据和趋势分析
class InteractiveLineChart extends StatefulWidget {
  final List<int> data;
  final List<String> labels;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;
  final Color lineColor;
  final Color pointColor;
  final Color fillColor;

  const InteractiveLineChart({
    super.key,
    required this.data,
    required this.labels,
    required this.title,
    this.xAxisLabel = '',
    this.yAxisLabel = '',
    this.lineColor = const Color(0xFFFFD700),
    this.pointColor = const Color(0xFF4FC3F7),
    this.fillColor = const Color(0xFFFFD700),
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _hoveredIndex = -1;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    if (widget.data.isEmpty || widget.labels.isEmpty) {
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
                if (_hoveredIndex != -1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.lineColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.lineColor, width: 1),
                    ),
                    child: Text(
                      '${widget.labels[_hoveredIndex]}: ${widget.data[_hoveredIndex]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.lineColor.shade700,
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
                    painter: LineChartPainter(
                      data: widget.data,
                      labels: widget.labels,
                      animationValue: _animation.value,
                      hoveredIndex: _hoveredIndex,
                      hoverPosition: _hoverPosition,
                      lineColor: widget.lineColor,
                      pointColor: widget.pointColor,
                      fillColor: widget.fillColor,
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
                            _hoverPosition = null;
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
    _findNearestPoint(localPosition);
  }

  void _handleHover(Offset localPosition) {
    _findNearestPoint(localPosition);
    setState(() {
      _hoverPosition = localPosition;
    });
  }

  void _findNearestPoint(Offset localPosition) {
    if (widget.data.isEmpty) return;

    const padding = 60.0;
    final chartWidth = 280 - padding * 2;
    final stepWidth = chartWidth / (widget.data.length - 1);
    
    double minDistance = double.infinity;
    int nearestIndex = -1;
    
    for (int i = 0; i < widget.data.length; i++) {
      final x = padding + stepWidth * i;
      final distance = (localPosition.dx - x).abs();
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    if (minDistance < stepWidth / 2) {
      setState(() {
        _hoveredIndex = nearestIndex;
      });
    } else {
      setState(() {
        _hoveredIndex = -1;
      });
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final double animationValue;
  final int hoveredIndex;
  final Offset? hoverPosition;
  final Color lineColor;
  final Color pointColor;
  final Color fillColor;
  final String xAxisLabel;
  final String yAxisLabel;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.animationValue,
    required this.hoveredIndex,
    this.hoverPosition,
    required this.lineColor,
    required this.pointColor,
    required this.fillColor,
    required this.xAxisLabel,
    required this.yAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padding = 60.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    final maxValue = data.reduce(math.max).toDouble();
    final minValue = data.reduce(math.min).toDouble();
    final valueRange = maxValue - minValue;
    
    if (valueRange == 0) return;
    
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
    
    // 绘制网格线和Y轴标签
    for (int i = 0; i <= 5; i++) {
      final y = size.height - padding - (chartHeight / 5 * i);
      final value = minValue + (valueRange / 5 * i);
      
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
          text: value.toInt().toString(),
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
    
    // 计算数据点位置
    final points = <Offset>[];
    final stepWidth = chartWidth / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final x = padding + stepWidth * i;
      final normalizedValue = (data[i] - minValue) / valueRange;
      final y = size.height - padding - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }
    
    // 绘制填充区域（渐变）
    if (animationValue > 0.3) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height - padding);
      
      for (int i = 0; i < points.length; i++) {
        final animatedIndex = (i * animationValue).clamp(0, points.length - 1).toInt();
        if (animatedIndex < points.length) {
          final point = points[animatedIndex];
          fillPath.lineTo(point.dx, point.dy);
        }
      }
      
      fillPath.lineTo(points.last.dx, size.height - padding);
      fillPath.close();
      
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withOpacity(0.3),
            fillColor.withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, padding, size.width, chartHeight));
      
      canvas.drawPath(fillPath, fillPaint);
    }
    
    // 绘制线条
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        final currentIndex = (i * animationValue).clamp(0, points.length - 1).toInt();
        if (currentIndex < points.length) {
          // 使用贝塞尔曲线使线条更平滑
          final current = points[currentIndex];
          final previous = points[currentIndex - 1];
          
          final controlPoint1 = Offset(
            previous.dx + (current.dx - previous.dx) * 0.5,
            previous.dy,
          );
          final controlPoint2 = Offset(
            previous.dx + (current.dx - previous.dx) * 0.5,
            current.dy,
          );
          
          linePath.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            current.dx,
            current.dy,
          );
        }
      }
      
      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(linePath, linePaint);
    }
    
    // 绘制数据点
    for (int i = 0; i < points.length; i++) {
      final animatedIndex = (i * animationValue).toInt();
      if (animatedIndex < points.length) {
        final point = points[i];
        final isHovered = hoveredIndex == i;
        
        // 外圈
        canvas.drawCircle(
          point,
          isHovered ? 8 : 6,
          Paint()..color = Colors.white,
        );
        
        // 内圈
        canvas.drawCircle(
          point,
          isHovered ? 6 : 4,
          Paint()..color = isHovered ? pointColor : lineColor,
        );
        
        // 悬停效果
        if (isHovered) {
          // 光晕效果
          canvas.drawCircle(
            point,
            12,
            Paint()
              ..color = pointColor.withOpacity(0.2)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      }
    }
    
    // 绘制X轴标签
    for (int i = 0; i < labels.length; i++) {
      if (i < points.length) {
        final point = points[i];
        final isHovered = hoveredIndex == i;
        
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i].length > 3 
                ? labels[i].substring(0, 3) 
                : labels[i],
            style: TextStyle(
              color: isHovered ? Colors.black87 : Colors.grey[600],
              fontSize: 10,
              fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            point.dx - labelPainter.width / 2,
            size.height - padding + 8,
          ),
        );
      }
    }
    
    // 绘制悬停线（垂直线）
    if (hoveredIndex != -1 && animationValue > 0.8) {
      final hoverPoint = points[hoveredIndex];
      final hoverLinePaint = Paint()
        ..color = pointColor.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(hoverPoint.dx, padding),
        Offset(hoverPoint.dx, size.height - padding),
        hoverLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.hoveredIndex != hoveredIndex ||
           oldDelegate.hoverPosition != hoverPosition;
  }
}