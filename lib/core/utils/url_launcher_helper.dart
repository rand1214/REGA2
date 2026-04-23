import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UrlLauncherHelper {
  /// Opens a YouTube video URL
  /// Tries to open in YouTube app first, falls back to browser
  static Future<void> openYouTubeVideo(
    BuildContext context,
    String videoUrl,
  ) async {
    if (videoUrl.isEmpty) {
      _showError(context, 'بەستەری ڤیدیۆ نییە');
      return;
    }

    try {
      final Uri url = Uri.parse(videoUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) _showError(context, 'ناتوانرێت ڤیدیۆکە بکرێتەوە');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'هەڵەیەک ڕوویدا: ${e.toString()}');
    }
  }

  /// Show error message as SnackBar
  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Peshang',
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
