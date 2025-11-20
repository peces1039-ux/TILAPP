import 'package:flutter/material.dart';

class FishLoading extends StatefulWidget {
  final String? message;
  final double size;

  const FishLoading({
    super.key,
    this.message,
    this.size = 100,
  });

  @override
  State<FishLoading> createState() => _FishLoadingState();
}

class _FishLoadingState extends State<FishLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_animation.value * 0.4),
                child: Transform.rotate(
                  angle: _animation.value * 6.28, // Rotación completa
                  child: Opacity(
                    opacity: 0.6 + (_animation.value * 0.4),
                    child: Icon(
                      Icons.bubble_chart,
                      size: widget.size,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

