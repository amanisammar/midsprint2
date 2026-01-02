import 'package:flutter/material.dart';

/// PillLogo draws a simple capsule (pill) using vector painting.
/// No external assets or packages required.
class PillLogo extends StatelessWidget {
  final double size;
  final List<Color>? colors;
  final bool showBadgeCircle;
  final bool showHalo;

  const PillLogo({
    super.key,
    this.size = 64,
    this.colors,
    this.showBadgeCircle = false,
    this.showHalo = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = colors ?? [
      const Color(0xFF7EE8D8), // mint
      const Color(0xFFB3E5FC), // sky blue
    ];
    Widget logo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PillPainter(themeColors),
      ),
    );

    if (showBadgeCircle || showHalo) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showHalo)
              Container(
                width: size * 1.3,
                height: size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB3E5FC).withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            if (showBadgeCircle)
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F0FF),
                  shape: BoxShape.circle,
                ),
              ),
            logo,
          ],
        ),
      );
    }

    return logo;
  }
}

/// Animated version of PillLogo with scale/opacity pop and slight bounce.
class PillLogoAnimated extends StatefulWidget {
  final double size;
  final bool showBadgeCircle;
  final bool showHalo;
  final List<Color>? colors;

  const PillLogoAnimated({
    super.key,
    this.size = 64,
    this.showBadgeCircle = true,
    this.showHalo = true,
    this.colors,
  });

  @override
  State<PillLogoAnimated> createState() => _PillLogoAnimatedState();
}

class _PillLogoAnimatedState extends State<PillLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_ctrl);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: PillLogo(
              size: widget.size,
              showBadgeCircle: widget.showBadgeCircle,
              showHalo: widget.showHalo,
              colors: widget.colors,
            ),
          ),
        );
      },
    );
  }
}

class _PillPainter extends CustomPainter {
  final List<Color> colors;
  _PillPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw capsule outer shape (rounded rectangle)
    final radius = size.height / 2.1;
    final rect = Rect.fromLTWH(
        size.width * 0.18, size.height * 0.10, size.width * 0.64, size.height * 0.78);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rRect, paint);

    // Capsule outline
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.07
      ..color = const Color(0xFF2C8D80);
    canvas.drawRRect(rRect, outline);

    // Divider line to mimic two-color pill halves
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = size.height * 0.04
      ..style = PaintingStyle.stroke;
    final dividerPath = Path()
      ..moveTo(size.width * 0.5, rect.top)
      ..lineTo(size.width * 0.5, rect.bottom);
    canvas.drawPath(dividerPath, dividerPaint);

    // Soft highlight band on top half
    final Shader highlight = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
        Colors.white.withValues(alpha: 0.45),
          Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final highlightRect = Rect.fromLTWH(
        rect.left + rect.width * 0.05, rect.top + rect.height * 0.08,
        rect.width * 0.90, rect.height * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(radius)),
      Paint()..shader = highlight,
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 2)), Radius.circular(radius)),
      shadowPaint,
    );

    // Face (eyes + mouth) on top (white) half
    final eyePaint = Paint()..color = const Color(0xFF1F2937);
    final blushPaint = Paint()..color = const Color(0xFFFF9DB0); // softer pink
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height * 0.04
      ..color = const Color(0xFF1F2937);

    final eyeRadius = size.height * 0.035;
    final eyeY = rect.top + rect.height * 0.33;
    final eyeLeftX = rect.left + rect.width * 0.38;
    final eyeRightX = rect.right - rect.width * 0.38;
    canvas.drawCircle(Offset(eyeLeftX, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(eyeRightX, eyeY), eyeRadius, eyePaint);

    // Blush
    final blushRadius = size.height * 0.036; // slightly larger blush
    canvas.drawCircle(
        Offset(eyeLeftX - rect.width * 0.12, eyeY + rect.height * 0.06), blushRadius, blushPaint);
    canvas.drawCircle(
        Offset(eyeRightX + rect.width * 0.12, eyeY + rect.height * 0.06), blushRadius, blushPaint);

    // Mouth (small arc)
    final mouthStart = Offset(rect.left + rect.width * 0.46, eyeY + rect.height * 0.10);
    final mouthEnd = Offset(rect.right - rect.width * 0.46, eyeY + rect.height * 0.10);
    final mouthPath = Path()
      ..moveTo(mouthStart.dx, mouthStart.dy)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.50,
        mouthStart.dy + rect.height * 0.06,
        mouthEnd.dx,
        mouthEnd.dy,
      );
    canvas.drawPath(mouthPath, mouthPaint);

    // Heart-shaped bow under the face
    final bowPaint = Paint()..color = const Color(0xFFFA718E);
    final bowCenterY = eyeY + rect.height * 0.16;
    final bowCenterX = rect.left + rect.width * 0.50;
    final heartWidth = rect.width * 0.36;
    final heartHeight = rect.height * 0.18;
    final heartPath = Path()
      ..moveTo(bowCenterX, bowCenterY)
      ..cubicTo(
        bowCenterX - heartWidth * 0.25,
        bowCenterY - heartHeight * 0.40,
        bowCenterX - heartWidth * 0.52,
        bowCenterY + heartHeight * 0.05,
        bowCenterX,
        bowCenterY + heartHeight * 0.55,
      )
      ..cubicTo(
        bowCenterX + heartWidth * 0.52,
        bowCenterY + heartHeight * 0.05,
        bowCenterX + heartWidth * 0.25,
        bowCenterY - heartHeight * 0.40,
        bowCenterX,
        bowCenterY,
      );
    canvas.drawPath(heartPath, bowPaint);
  }

  @override
  bool shouldRepaint(covariant _PillPainter oldDelegate) => false;
}
