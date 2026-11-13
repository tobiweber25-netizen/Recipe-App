import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final int? apkSizeBytes;
  final String publishedAt;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    this.apkSizeBytes,
    this.publishedAt = '',
  });

  String get formattedSize {
    if (apkSizeBytes == null || apkSizeBytes! <= 0) return '';
    final mb = apkSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class AppUpdateManager {
  static const String defaultRepo = 'tobiweber25-netizen/Recipe-App';
  static const MethodChannel _channel = MethodChannel('com.example.seasonal_prep_cook/installer');

  final http.Client _client;

  AppUpdateManager({http.Client? client}) : _client = client ?? http.Client();

  /// Retrieve current version from Android PackageManager or default fallback.
  Future<String> getCurrentVersion() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
        if (result != null && result['versionName'] != null) {
          return result['versionName'].toString();
        }
      } catch (e) {
        debugPrint('AppUpdateManager: failed getting native version: $e');
      }
    }
    return '1.0.0';
  }

  /// Compares semantic versions (e.g. "1.0.0" vs "1.0.1", "v1.2" vs "1.2.0")
  static bool isNewerVersion(String current, String latest) {
    final cleanCurrent = _cleanVersion(current);
    final cleanLatest = _cleanVersion(latest);

    final currentParts = cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final latestParts = cleanLatest.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;
    while (currentParts.length < maxLen) {
      currentParts.add(0);
    }
    while (latestParts.length < maxLen) {
      latestParts.add(0);
    }

    for (int i = 0; i < maxLen; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static String _cleanVersion(String v) {
    String clean = v.trim();
    if (clean.toLowerCase().startsWith('v')) {
      clean = clean.substring(1);
    }
    final plusIndex = clean.indexOf('+');
    if (plusIndex != -1) {
      clean = clean.substring(0, plusIndex);
    }
    final dashIndex = clean.indexOf('-');
    if (dashIndex != -1) {
      clean = clean.substring(0, dashIndex);
    }
    return clean;
  }

  /// Checks GitHub Releases API for latest published release.
  Future<AppUpdateInfo> checkForUpdate({String? repoOverride}) async {
    final repo = repoOverride ?? dotenv.env['GITHUB_UPDATE_REPO'] ?? defaultRepo;
    final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');

    final currentVersion = await getCurrentVersion();

    final response = await _client.get(
      url,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'SeasonalPrepCook-App',
      },
    );

    if (response.statusCode == 404) {
      return AppUpdateInfo(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseName: 'No Releases Found',
        releaseNotes: 'No releases found on GitHub repository $repo.',
      );
    }

    if (response.statusCode != 200) {
      throw HttpException('GitHub API error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (data['tag_name'] as String?) ?? '';
    final releaseName = (data['name'] as String?) ?? tagName;
    final releaseNotes = (data['body'] as String?) ?? 'No release notes provided.';
    final publishedAt = (data['published_at'] as String?) ?? '';

    String? apkUrl;
    int? apkSize;

    final assets = (data['assets'] as List<dynamic>?) ?? [];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkSize = asset['size'] as int?;
          break;
        }
      }
    }

    final hasUpdate = isNewerVersion(currentVersion, tagName);

    return AppUpdateInfo(
      hasUpdate: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: tagName.isNotEmpty ? tagName : currentVersion,
      releaseName: releaseName,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      publishedAt: publishedAt,
    );
  }

  /// Downloads the APK and triggers system package installation intent.
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/seasonal_prep_cook_update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    request.headers['User-Agent'] = 'SeasonalPrepCook-App';
    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw HttpException('Failed to download update APK: HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? -1;
    int receivedBytes = 0;

    final sink = file.openWrite();
    try {
      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        onProgress(progress, receivedBytes, totalBytes);
      }).asFuture();
    } finally {
      await sink.flush();
      await sink.close();
    }

    if (!kIsWeb && Platform.isAndroid) {
      await _channel.invokeMethod('installApk', {'filePath': file.path});
    } else {
      debugPrint('Install not supported on this platform: ${file.path}');
    }
  }
}
