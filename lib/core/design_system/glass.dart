import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class Palette {
  static const background = Color(0xFF0D101B);
  static const violet = Color(0xFFB89AFF);
  static const cyan = Color(0xFF41DBE9);
  static const coral = Color(0xFFFF756C);
  static const radius = 28.0;
}
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool reduced;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.reduced = false});
  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Palette.radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: light ? [Colors.white.withValues(alpha: .85), Colors.white.withValues(alpha: .65)] : [const Color(0xFF323546).withValues(alpha: .8), const Color(0xFF181B29).withValues(alpha: .85)]),
        border: Border.all(color: light ? Colors.black12 : Colors.white.withValues(alpha: .13)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: reduced ? 0 : 24, offset: const Offset(0, 12))],
      ), child: child,
    );
    return ClipRRect(borderRadius: BorderRadius.circular(Palette.radius),
      child: reduced ? panel : BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: panel));
  }
}
class GlassAvatar extends StatelessWidget {
  final String name;
  final int index;
  final bool online;
  final double radius;
  const GlassAvatar(this.name, {super.key, this.index = 0, this.online = false, this.radius = 25});
  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: index.isEven ? [Palette.violet, const Color(0xFF6750A4)] : [Palette.cyan, const Color(0xFF16728E)]),
        border: Border.all(color: Colors.white24, width: 2)),
      alignment: Alignment.center, child: Text(name.isEmpty ? '?' : name.substring(0, 1), style: TextStyle(fontSize: radius * .75, color: Colors.white, fontWeight: FontWeight.bold))),
    if (online) Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF4CE0AC), shape: BoxShape.circle, border: Border.all(color: Palette.background, width: 2)))),
  ]);
}
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  const GlassButton(this.label, {super.key, required this.onPressed, this.icon = Icons.arrow_forward_rounded});
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label),
    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: Palette.violet, foregroundColor: Palette.background));
}
