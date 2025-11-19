// Summary Card Widget
// Related: T040, FR-001
// Reusable card component for dashboard metrics

import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 26, color: cardColor),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
