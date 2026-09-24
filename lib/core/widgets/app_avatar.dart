import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Standard, secure Avatar widget for OpenAsk.
/// Strictly enforces HTTPS remote image URLs or initials fallback.
/// No base64 data, no Firebase Storage.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final bool isAnonymous;
  final double radius;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.isAnonymous = false,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isAnonymous) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.masks_outlined,
          size: radius * 1.1,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final hasValidHttpUrl = photoUrl != null &&
        photoUrl!.isNotEmpty &&
        (photoUrl!.startsWith('https://') || photoUrl!.startsWith('http://'));

    if (hasValidHttpUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (context, url, error) => _buildInitials(context),
          ),
        ),
      );
    }

    return _buildInitials(context);
  }

  Widget _buildInitials(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
