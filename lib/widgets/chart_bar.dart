import 'dart:math';
import 'package:flutter/material.dart';

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.fill,
    required this.icon,
    required this.label,
    required this.color, // <--- AHORA RECIBE COLOR
  });

  final double fill;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color), // Icono del color del tema (rojo/verde)
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            width: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              heightFactor: fill,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.8), // Barra del color recibido
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: FittedBox(
            child: Text(
              label.substring(0, min(label.length, 4)),
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
