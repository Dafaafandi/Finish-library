import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for handling file downloads
class DownloadHelper {
  /// Download a file from the given URL with multiple fallback methods
  static Future<bool> downloadFile({
    required String url,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      print('DownloadHelper: Attempting to download from: $url');

      // Clean up the URL - remove double slashes and fix protocol
      String cleanUrl = _cleanUrl(url);
      print('DownloadHelper: Cleaned URL: $cleanUrl');

      final Uri downloadUri = Uri.parse(cleanUrl);

      // Try different launch modes for better compatibility
      bool launched = false;

      // Method 1: External application mode (recommended for downloads)
      try {
        if (await canLaunchUrl(downloadUri)) {
          launched = await launchUrl(
            downloadUri,
            mode: LaunchMode.externalApplication,
          );
          print('DownloadHelper: External application mode success: $launched');
        }
      } catch (e) {
        print('DownloadHelper: External application mode failed: $e');
      }

      // Method 2: Platform default mode
      if (!launched) {
        try {
          launched = await launchUrl(
            downloadUri,
            mode: LaunchMode.platformDefault,
          );
          print('DownloadHelper: Platform default mode success: $launched');
        } catch (e) {
          print('DownloadHelper: Platform default mode failed: $e');
        }
      }

      // Method 3: External non-browser mode
      if (!launched) {
        try {
          launched = await launchUrl(
            downloadUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          print('DownloadHelper: External non-browser mode success: $launched');
        } catch (e) {
          print('DownloadHelper: External non-browser mode failed: $e');
        }
      }

      // Method 4: In-app web view (last resort)
      if (!launched) {
        try {
          launched = await launchUrl(
            downloadUri,
            mode: LaunchMode.inAppWebView,
          );
          print('DownloadHelper: In-app web view mode success: $launched');
        } catch (e) {
          print('DownloadHelper: In-app web view mode failed: $e');
        }
      }

      if (launched) {
        _showSuccessMessage(context, fileName);
        return true;
      } else {
        _showErrorMessage(context, 'Could not launch download URL: $cleanUrl');
        return false;
      }
    } catch (e) {
      print('DownloadHelper: General error: $e');
      _showErrorMessage(context, 'Download failed: ${e.toString()}');
      return false;
    }
  }

  /// Clean up URL by removing double slashes and fixing protocol
  static String _cleanUrl(String url) {
    return url
        .replaceAll(RegExp(r'([^:])//+'),
            r'$1/') // Remove double slashes except after protocol
        .replaceFirst(RegExp(r'^http:/(?!/)'), 'http://') // Fix http protocol
        .replaceFirst(
            RegExp(r'^https:/(?!/)'), 'https://'); // Fix https protocol
  }

  /// Show success message to user
  static void _showSuccessMessage(BuildContext context, String fileName) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Download started! File $fileName will be saved to your Downloads folder.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message to user
  static void _showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Validate if URL is properly formatted
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
