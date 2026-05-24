import 'package:flutter/material.dart';
import '../app_theme.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const MicButton({super.key, required this.isListening, required this.onTap});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isListening ? AppTheme.accent : AppTheme.surface;
    final iconColor = widget.isListening ? AppTheme.bg : AppTheme.textPrimary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: widget.isListening ? _scale.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.isListening
                ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4)]
                : [],
          ),
          child: Icon(
            widget.isListening ? Icons.mic : Icons.mic_none,
            size: 52,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
