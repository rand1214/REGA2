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
      _showError(context, 'بەستەری ڤیدیۆ نییە'); // "No video link"
      return;
    }

    try {
      final Uri url = Uri.parse(videoUrl);

      // Check if URL can be launched
      if (await canLaunchUrl(url)) {
        // Launch URL
        // mode: LaunchMode.externalApplication opens in YouTube app or browser
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showError(context, 'ناتوانرێت ڤیدیۆکە بکرێتەوە'); // "Cannot open video"
      }
    } catch (e) {
      _showError(context, 'هەڵەیەک ڕوویدا: ${e.toString()}'); // "Error occurred"
    }
  }

  /// Opens any URL (for future use)
  static Future<void> openUrl(
    BuildContext context,
    String urlString, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    if (urlString.isEmpty) {
      _showError(context, 'بەستەر نییە'); // "No link"
      return;
    }

    try {
      final Uri url = Uri.parse(urlString);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: mode);
      } else {
        _showError(context, 'ناتوانرێت بەستەرەکە بکرێتەوە'); // "Cannot open link"
      }
    } catch (e) {
      _showError(context, 'هەڵەیەک ڕوویدا: ${e.toString()}');
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
