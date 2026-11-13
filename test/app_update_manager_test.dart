import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seasonal_prep_cook/services/app_update_manager.dart';

void main() {
  group('AppUpdateManager Semantic Version Comparison', () {
    test('detects patch, minor, and major version increments', () {
      expect(AppUpdateManager.isNewerVersion('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.0.9', '1.1.0'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.9.9', '2.0.0'), isTrue);
    });

    test('returns false when latest is equal or older', () {
      expect(AppUpdateManager.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateManager.isNewerVersion('1.0.1', '1.0.0'), isFalse);
      expect(AppUpdateManager.isNewerVersion('2.0.0', '1.9.9'), isFalse);
    });

    test('handles v prefix and build number suffixes cleanly', () {
      expect(AppUpdateManager.isNewerVersion('v1.0.0', 'v1.0.1'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.0.0+1', 'v1.0.1'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.0.0+2', '1.0.0'), isFalse);
      expect(AppUpdateManager.isNewerVersion('v1.2.0-beta', '1.2.1'), isTrue);
    });

    test('handles different dot segments count', () {
      expect(AppUpdateManager.isNewerVersion('1.0', '1.0.1'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.0.0', '1.1'), isTrue);
      expect(AppUpdateManager.isNewerVersion('1.0.1', '1.0'), isFalse);
    });
  });

  group('AppUpdateInfo Formatting', () {
    test('formats APK size in MB correctly', () {
      const info = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        releaseName: 'v1.0.1 Update',
        releaseNotes: 'Bug fixes',
        apkDownloadUrl: 'https://github.com/test/app.apk',
        apkSizeBytes: 25690112, // ~24.5 MB
      );

      expect(info.formattedSize, '24.5 MB');
    });

    test('returns empty string for null or zero size', () {
      const info = AppUpdateInfo(
        hasUpdate: false,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        releaseName: 'Current',
        releaseNotes: '',
      );

      expect(info.formattedSize, '');
    });
  });

  group('AppUpdateManager GitHub API Mock Tests', () {
    test('parses release payload and detects update available', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          final body = jsonEncode({
            'tag_name': 'v1.0.1',
            'name': 'Wireless Update v1.0.1',
            'body': '- Added new seasonal spring dishes\n- Improved performance',
            'published_at': '2026-11-13T12:00:00Z',
            'assets': [
              {
                'name': 'recipe-app-release.apk',
                'browser_download_url': 'https://github.com/tobiweber25-netizen/Recipe-App/releases/download/v1.0.1/recipe-app-release.apk',
                'size': 20971520, // 20 MB
              }
            ]
          });
          return http.Response(body, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final manager = AppUpdateManager(client: mockClient);
      final updateInfo = await manager.checkForUpdate(repoOverride: 'tobiweber25-netizen/Recipe-App');

      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.latestVersion, 'v1.0.1');
      expect(updateInfo.releaseName, 'Wireless Update v1.0.1');
      expect(updateInfo.releaseNotes, contains('seasonal spring dishes'));
      expect(updateInfo.apkDownloadUrl, contains('recipe-app-release.apk'));
      expect(updateInfo.formattedSize, '20.0 MB');
    });

    test('handles 404 when no releases are published yet', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final manager = AppUpdateManager(client: mockClient);
      final updateInfo = await manager.checkForUpdate(repoOverride: 'tobiweber25-netizen/Recipe-App');

      expect(updateInfo.hasUpdate, isFalse);
      expect(updateInfo.releaseName, 'No Releases Found');
    });
  });
}
