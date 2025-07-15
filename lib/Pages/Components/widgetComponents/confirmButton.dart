import 'package:flutter/material.dart';
import 'dart:math';

import 'package:get/get.dart';

class ParabolicButton extends StatefulWidget {
  final VoidCallback onPressed;

  ParabolicButton({super.key, required this.onPressed});

  @override
  State<ParabolicButton> createState() => _ParabolicButtonState();
}

class _ParabolicButtonState extends State<ParabolicButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPressed = false;
  DateTime? _pressStartTime;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          widget.onPressed();
        }
      });
  }

  void _onTapDown(TapDownDetails details) {
    if (!_completed) {
      _pressStartTime = DateTime.now();
      _controller.forward();
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_completed) {
      _controller.reset();
    }
    setState(() {
      _isPressed = false;
      _completed = false;
    });
  }

  void _onTapCancel() {
    if (!_completed) {
      _controller.reset();
    }
    setState(() {
      _isPressed = false;
      _completed = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: ClipPath(
              clipper: HalfParabolaClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: _isPressed
                      ? const Color(0xFFD6C79F)
                      : const Color(0xFFEFE3C2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'confirmButton'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: ButtonOutlinePainter(_animation.value),
            size: Size(MediaQuery.of(context).size.width, 100),
          ),
        ],
      ),
    );
  }
}

class HalfParabolaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height * 0.5,
      size.width,
      size.height,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ButtonOutlinePainter extends CustomPainter {
  final double progress;

  ButtonOutlinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFEFE3C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height * 0.5,
      size.width,
      size.height,
    );

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    final offset = totalLength * progress;

    final extractedPath = metrics.extractPath(0, offset);

    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(covariant ButtonOutlinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
