import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum InstallStatus {
  launched,
  permissionRequired,
  unsupportedPlatform,
}

class InstallOutcome {
  final InstallStatus status;
  final String apkFilePath;

  const InstallOutcome({
    required this.status,
    required this.apkFilePath,
  });
}

class UpdateCancelledException implements Exception {
  const UpdateCancelledException();

  @override
  String toString() => 'Download cancelled.';
}

class UpdateCancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

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
  static const String _apkFilePrefix = 'seasonal_prep_cook_';

  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _tempDirProvider;

  AppUpdateManager({
    http.Client? client,
    Future<Directory> Function()? tempDirProvider,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _tempDirProvider = tempDirProvider ?? getTemporaryDirectory;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Ensures a single leading 'v' prefix for display labels (e.g. "v1.0.1").
  static String formatVersionLabel(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) return 'v1.0.0';
    return trimmed.toLowerCase().startsWith('v') ? 'v${trimmed.substring(1)}' : 'v$trimmed';
  }

  String _resolveRepo(String? repoOverride) {
    final override = repoOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    if (dotenv.isInitialized) {
      final envRepo = dotenv.env['GITHUB_UPDATE_REPO']?.trim();
      if (envRepo != null && envRepo.isNotEmpty) return envRepo;
    }
    return defaultRepo;
  }

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

  /// Checks whether Android allows this app to request package installations.
  Future<bool> canInstallPackages() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final allowed = await _channel.invokeMethod<bool>('canInstallPackages');
        return allowed ?? false;
      } catch (e) {
        debugPrint('AppUpdateManager: failed checking install permission: $e');
        return false;
      }
    }
    return true;
  }

  /// Opens the Android "Install unknown apps" settings page for this app.
  Future<void> openInstallPermissionSettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      await _channel.invokeMethod('openInstallPermissionSettings');
    }
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

  static String _cacheFileNameForTag(String? versionTag) {
    final raw = (versionTag ?? 'update').trim();
    final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$_apkFilePrefix${sanitized.isEmpty ? 'update' : sanitized}.apk';
  }

  static Future<bool> _hasValidZipHeader(File file) async {
    if (!await file.exists()) return false;
    final raf = await file.open();
    try {
      final header = await raf.read(4);
      return header.length == 4 &&
          header[0] == 0x50 &&
          header[1] == 0x4B &&
          header[2] == 0x03 &&
          header[3] == 0x04;
    } finally {
      await raf.close();
    }
  }

  /// Removes old cached APK files left over from previous updates.
  Future<void> cleanupCachedApks({String? keepFileName}) async {
    if (kIsWeb) return;
    try {
      final tempDir = await _tempDirProvider();
      if (!await tempDir.exists()) return;
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final name = entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : '';
          final isUpdateArtifact = name.startsWith(_apkFilePrefix) &&
              (name.endsWith('.apk') || name.endsWith('.apk.part'));
          if (isUpdateArtifact && name != keepFileName) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('AppUpdateManager: cache cleanup skipped: $e');
    }
  }

  /// Checks GitHub Releases API for latest published release.
  Future<AppUpdateInfo> checkForUpdate({String? repoOverride}) async {
    final repo = _resolveRepo(repoOverride);
    final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');

    final currentVersion = await getCurrentVersion();

    http.Response response;
    try {
      response = await _client
          .get(
            url,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'SeasonalPrepCook-App',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Connection timed out while checking GitHub for updates.');
    } on SocketException {
      throw Exception('No internet connection. Please connect and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach GitHub right now. Please try again.');
    }

    if (response.statusCode == 404) {
      return AppUpdateInfo(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseName: 'No Releases Found',
        releaseNotes: 'No releases found on GitHub repository $repo.',
      );
    }

    if (response.statusCode == 403 && response.headers['x-ratelimit-remaining'] == '0') {
      throw Exception('GitHub update check limit reached. Please try again in a few minutes.');
    }

    if (response.statusCode != 200) {
      throw HttpException('GitHub returned an error (HTTP ${response.statusCode}). Please try again later.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (data['tag_name'] as String?) ?? '';
    final releaseName = (data['name'] as String?)?.trim().isNotEmpty == true
        ? (data['name'] as String).trim()
        : tagName;
    final releaseNotes = (data['body'] as String?)?.trim() ?? 'No release notes provided.';
    final publishedAt = (data['published_at'] as String?) ?? '';

    String? apkUrl;
    int? apkSize;

    final assets = (data['assets'] as List<dynamic>?) ?? [];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String?) ?? '';
        final lowerName = name.toLowerCase();
        if (lowerName.endsWith('.apk') && !lowerName.contains('debug')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkSize = (asset['size'] as num?)?.toInt();
          if (lowerName.contains('release')) break;
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

  /// Downloads (or reuses a verified cached copy of) the update APK and returns its file path.
  Future<String> downloadApk({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    String? versionTag,
    int? expectedSizeBytes,
    UpdateCancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.scheme != 'https') {
      throw Exception('Invalid update download link.');
    }

    final tempDir = await _tempDirProvider();
    final targetName = _cacheFileNameForTag(versionTag);
    final file = File('${tempDir.path}/$targetName');
    final partFile = File('${tempDir.path}/$targetName.part');

    // Reuse already verified cached APK for this exact version to avoid re-downloading
    if (await file.exists()) {
      final existingSize = await file.length();
      final sizeMatches = expectedSizeBytes == null || expectedSizeBytes <= 0 || existingSize == expectedSizeBytes;
      if (existingSize > 0 && sizeMatches && await _hasValidZipHeader(file)) {
        await cleanupCachedApks(keepFileName: targetName);
        onProgress(1.0, existingSize, existingSize);
        return file.path;
      }
      await file.delete();
    }

    await cleanupCachedApks();
    if (await partFile.exists()) {
      await partFile.delete();
    }

    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = 'SeasonalPrepCook-App';

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Connection timed out while starting the download.');
    } on SocketException {
      throw Exception('No internet connection. Please connect and try again.');
    } on http.ClientException {
      throw Exception('Download could not start. Please try again.');
    }

    if (response.statusCode != 200) {
      throw HttpException('Failed to download update (HTTP ${response.statusCode}).');
    }

    final headerTotal = response.contentLength ?? -1;
    final totalBytes = headerTotal > 0 ? headerTotal : (expectedSizeBytes ?? -1);
    int receivedBytes = 0;

    final sink = partFile.openWrite();
    final completer = Completer<void>();
    late final StreamSubscription<List<int>> subscription;
    DateTime lastProgressEmit = DateTime.fromMillisecondsSinceEpoch(0);

    try {
      subscription = response.stream
          .timeout(const Duration(seconds: 30))
          .listen(
            (chunk) {
              if (cancelToken?.isCancelled ?? false) {
                subscription.cancel();
                if (!completer.isCompleted) {
                  completer.completeError(const UpdateCancelledException());
                }
                return;
              }
              sink.add(chunk);
              receivedBytes += chunk.length;
              final now = DateTime.now();
              if (now.difference(lastProgressEmit).inMilliseconds >= 100 ||
                  (totalBytes > 0 && receivedBytes >= totalBytes)) {
                lastProgressEmit = now;
                final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
                onProgress(progress, receivedBytes, totalBytes);
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!completer.isCompleted) {
                completer.completeError(error, stackTrace);
              }
            },
            cancelOnError: true,
          );

      await completer.future;
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await partFile.exists()) {
        await partFile.delete();
      }
      if (e is UpdateCancelledException) rethrow;
      if (e is TimeoutException) {
        throw Exception('Download stalled due to a slow connection. Please try again.');
      }
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Connection dropped during download. Please try again.');
      }
      rethrow;
    }

    if (receivedBytes <= 0) {
      if (await partFile.exists()) await partFile.delete();
      throw Exception('Downloaded update file was empty. Please try again.');
    }

    if (headerTotal > 0 && receivedBytes != headerTotal) {
      if (await partFile.exists()) await partFile.delete();
      throw Exception('Download was incomplete. Please try again.');
    }

    if (expectedSizeBytes != null && expectedSizeBytes > 0 && receivedBytes != expectedSizeBytes) {
      if (await partFile.exists()) await partFile.delete();
      throw Exception('Downloaded file size did not match the release. Please try again.');
    }

    if (!await _hasValidZipHeader(partFile)) {
      if (await partFile.exists()) await partFile.delete();
      throw Exception('Downloaded file is not a valid Android update package.');
    }

    await partFile.rename(file.path);
    onProgress(1.0, receivedBytes, totalBytes > 0 ? totalBytes : receivedBytes);
    return file.path;
  }

  /// Launches the Android package installer for an already-downloaded APK file.
  Future<InstallStatus> installApk(String filePath) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final rawResult = await _channel.invokeMethod<dynamic>('installApk', {'filePath': filePath});
        if (rawResult is Map) {
          final status = rawResult['status']?.toString();
          if (status == 'permission_required') {
            return InstallStatus.permissionRequired;
          }
          return InstallStatus.launched;
        }
        return InstallStatus.launched;
      } on PlatformException catch (e) {
        throw Exception(e.message ?? 'Could not open Android installer.');
      }
    }
    debugPrint('Install not supported on this platform: $filePath');
    return InstallStatus.unsupportedPlatform;
  }

  /// Downloads the APK and triggers system package installation intent.
  Future<InstallOutcome> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    String? versionTag,
    int? expectedSizeBytes,
    UpdateCancelToken? cancelToken,
  }) async {
    final apkPath = await downloadApk(
      downloadUrl: downloadUrl,
      onProgress: onProgress,
      versionTag: versionTag,
      expectedSizeBytes: expectedSizeBytes,
      cancelToken: cancelToken,
    );
    final status = await installApk(apkPath);
    return InstallOutcome(status: status, apkFilePath: apkPath);
  }
}
