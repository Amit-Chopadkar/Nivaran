import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumContactCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarPath;
  final IconData? fallbackIcon;
  final Color? iconBgColor;
  final VoidCallback onCallTap;
  final VoidCallback? onDeleteTap;
  final bool isPrimary;
  final bool isSelected;
  final VoidCallback? onTap;

  const PremiumContactCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarPath,
    this.fallbackIcon,
    this.iconBgColor,
    required this.onCallTap,
    this.onDeleteTap,
    this.isPrimary = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryPurple, width: 2)
              : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor ?? AppTheme.primaryRose.withValues(alpha: 0.5),
              ),
              child: ClipOval(
                child: avatarPath != null
                    ? Image.asset(
                        avatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
                      )
                    : _buildFallbackIcon(),
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B).withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDeleteTap != null)
                  IconButton(
                    onPressed: onDeleteTap,
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed.withValues(alpha: 0.7), size: 22),
                  ),
                GestureDetector(
                  onTap: onCallTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        fallbackIcon ?? Icons.person_rounded,
        color: AppTheme.primaryPurple.withValues(alpha: 0.6),
        size: 30,
      ),
    );
  }
}
