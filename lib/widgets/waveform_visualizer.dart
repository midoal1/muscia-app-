import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double maxHeight;
  final Color? color;

  const WaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 18,
    this.maxHeight = 36.0,
    this.color,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _heightMultipliers;

  @override
  void initState() {
    super.initState();
    _heightMultipliers = List.generate(widget.barCount, (_) => _random.nextDouble());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        if (mounted && widget.isPlaying) {
          setState(() {
            for (int i = 0; i < widget.barCount; i++) {
              _heightMultipliers[i] = 0.2 + (_random.nextDouble() * 0.8);
            }
          });
        }
      });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        setState(() {
          _heightMultipliers = List.generate(widget.barCount, (_) => 0.15);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.gazelleRedVibrant;

    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final barHeight = (widget.isPlaying
                  ? _heightMultipliers[index]
                  : 0.15) *
              widget.maxHeight;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.2),
            width: 3.2,
            height: barHeight.clamp(4.0, widget.maxHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor.withValues(alpha: 0.4),
                  activeColor,
                  AppColors.gazelleRedGlow,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: widget.isPlaying
                  ? [
                      BoxShadow(
                        color: AppColors.gazelleRedGlow.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
