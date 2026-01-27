import 'package:flutter/material.dart';

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final double delay;
  final Duration duration;
  final Offset offset;

  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 0.35), // Default slide up from 35% height
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
