import 'package:flutter/material.dart';

class HeureButtonAmeliore extends StatelessWidget {
  final String label;
  final String heure;
  final VoidCallback onTap;
  final Color couleur;

  const HeureButtonAmeliore({
    super.key,
    required this.label,
    required this.heure,
    required this.onTap,
    this.couleur = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: couleur.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
              color: couleur.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  heure,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: couleur,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: couleur,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
