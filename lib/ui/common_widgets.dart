import 'package:flutter/material.dart';

const Color kBrandTeal = Color(0xFF00897B);
const Color kBrandTealDark = Color(0xFF00574B);

/// App bar with the cafeteria's teal gradient and a subtle rounded bottom.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final double toolbarHeight;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.toolbarHeight = kToolbarHeight + 12,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBrandTeal, kBrandTealDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
    );
  }
}

/// Small coloured pill that tells the student how much of an item is left.
class StockBadge extends StatelessWidget {
  final int stock;

  const StockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    if (stock <= 0) {
      color = const Color(0xFFD32F2F);
      text = 'SOLD OUT';
    } else if (stock <= 5) {
      color = const Color(0xFFEF6C00);
      text = 'Only $stock left';
    } else {
      color = const Color(0xFF2E7D32);
      text = 'In stock: $stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// A receipt-style dashed separator.
class DashedDivider extends StatelessWidget {
  final Color color;

  const DashedDivider({super.key, this.color = const Color(0xFFCFD8DC)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Picks a food emoji for an item based on its name.
String foodEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('burger')) return '🍔';
  if (n.contains('bread')) return '🍞';
  if (n.contains('coffee')) return '☕';
  if (n.contains('tea')) return '🍵';
  if (n.contains('samosa')) return '🥟';
  if (n.contains('singara')) return '🥟';
  return '🍽';
}
