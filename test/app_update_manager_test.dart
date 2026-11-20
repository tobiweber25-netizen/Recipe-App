import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seasonal_prep_cook/services/app_update_manager.dart';
import 'package:seasonal_prep_cook/views/update_dialog.dart';

class _FakeUpdateManager extends AppUpdateManager {
  InstallStatus nextInstallStatus;
  bool installPermissionAllowed;
  int downloadCalls = 0;
  int installCalls = 0;

  _FakeUpdateManager({
    this.nextInstallStatus = InstallStatus.launched,
    this.installPermissionAllowed = true,
  });

  @override
  Future<bool> canInstallPackages() async => installPermissionAllowed;

  @override
  Future<void> openInstallPermissionSettings() async {}

  @override
  Future<String> downloadApk({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    String? versionTag,
    int? expectedSizeBytes,
    UpdateCancelToken? cancelToken,
  }) async {
    downloadCalls++;
    onProgress(1.0, expectedSizeBytes ?? 1024, expectedSizeBytes ?? 1024);
    return '/tmp/fake_update.apk';
  }

  @override
  Future<InstallStatus> installApk(String filePath) async {
    installCalls++;
    return nextInstallStatus;
  }
}

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

    test('works without repoOverride when dotenv is uninitialized', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/repos/${AppUpdateManager.defaultRepo}/releases/latest');
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.2',
            'name': 'v1.0.2',
            'body': 'Fixes',
            'assets': [
              {
                'name': 'app-debug.apk',
                'browser_download_url': 'https://github.com/example/app-debug.apk',
                'size': 100,
              },
              {
                'name': 'recipe-app-release.apk',
                'browser_download_url': 'https://github.com/example/recipe-app-release.apk',
                'size': 2048,
              },
            ],
          }),
          200,
        );
      });

      final manager = AppUpdateManager(client: mockClient);
      final info = await manager.checkForUpdate();
      expect(info.hasUpdate, isTrue);
      expect(info.apkDownloadUrl, 'https://github.com/example/recipe-app-release.apk');
      expect(info.apkSizeBytes, 2048);
    });

    test('formats GitHub 403 rate limit cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message":"API rate limit exceeded"}',
          403,
          headers: {'x-ratelimit-remaining': '0'},
        );
      });

      final manager = AppUpdateManager(client: mockClient);
      expect(
        () => manager.checkForUpdate(),
        throwsA(predicate((e) => e.toString().contains('rate limit') || e.toString().contains('limit reached'))),
      );
    });
  });

  group('AppUpdateManager Version Formatting & APK Download Verification', () {
    test('formatVersionLabel normalizes leading v prefix', () {
      expect(AppUpdateManager.formatVersionLabel('1.0.0'), 'v1.0.0');
      expect(AppUpdateManager.formatVersionLabel('v1.0.1'), 'v1.0.1');
      expect(AppUpdateManager.formatVersionLabel('V2.1.0'), 'v2.1.0');
    });

    test('downloads, verifies ZIP header, caches by tag, and reuses cached APK', () async {
      final tempDir = await Directory.systemTemp.createTemp('ota_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final staleFile = File('${tempDir.path}/seasonal_prep_cook_v1.0.0.apk');
      await staleFile.writeAsBytes([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);

      final fakeApkBytes = [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x08, 0x00, 0x08, 0x00];
      int requestCount = 0;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        requestCount++;
        return http.StreamedResponse(
          Stream.value(fakeApkBytes),
          200,
          contentLength: fakeApkBytes.length,
        );
      });

      final manager = AppUpdateManager(
        client: mockClient,
        tempDirProvider: () async => tempDir,
      );

      final path1 = await manager.downloadApk(
        downloadUrl: 'https://github.com/tobiweber25-netizen/Recipe-App/releases/download/v1.0.2/recipe-app-release.apk',
        versionTag: 'v1.0.2',
        expectedSizeBytes: fakeApkBytes.length,
        onProgress: (_, __, ___) {},
      );
      expect(File(path1).existsSync(), isTrue);
      expect(staleFile.existsSync(), isFalse);
      expect(requestCount, 1);

      // Second call for same version reuses verified cache without HTTP request
      final path2 = await manager.downloadApk(
        downloadUrl: 'https://github.com/tobiweber25-netizen/Recipe-App/releases/download/v1.0.2/recipe-app-release.apk',
        versionTag: 'v1.0.2',
        expectedSizeBytes: fakeApkBytes.length,
        onProgress: (_, __, ___) {},
      );
      expect(path2, path1);
      expect(requestCount, 1);
    });

    test('rejects invalid non-ZIP download payload (e.g. HTML error page)', () async {
      final tempDir = await Directory.systemTemp.createTemp('ota_bad_zip_');
      addTearDown(() => tempDir.delete(recursive: true));

      final htmlBytes = utf8.encode('<html><body>Error</body></html>');
      final mockClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(htmlBytes),
          200,
          contentLength: htmlBytes.length,
        );
      });

      final manager = AppUpdateManager(
        client: mockClient,
        tempDirProvider: () async => tempDir,
      );

      await expectLater(
        manager.downloadApk(
          downloadUrl: 'https://github.com/example/recipe-app-release.apk',
          versionTag: 'v1.0.2',
          onProgress: (_, __, ___) {},
        ),
        throwsA(predicate((e) => e.toString().contains('valid Android update package'))),
      );
      expect(tempDir.listSync(), isEmpty);
    });

    test('rejects truncated download when size mismatches expectedSizeBytes', () async {
      final tempDir = await Directory.systemTemp.createTemp('ota_trunc_');
      addTearDown(() => tempDir.delete(recursive: true));

      final partialApk = [0x50, 0x4B, 0x03, 0x04, 1, 2];
      final mockClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(partialApk),
          200,
          contentLength: partialApk.length,
        );
      });

      final manager = AppUpdateManager(
        client: mockClient,
        tempDirProvider: () async => tempDir,
      );

      await expectLater(
        manager.downloadApk(
          downloadUrl: 'https://github.com/example/recipe-app-release.apk',
          versionTag: 'v1.0.2',
          expectedSizeBytes: 5000,
          onProgress: (_, __, ___) {},
        ),
        throwsA(predicate((e) => e.toString().contains('size did not match'))),
      );
    });
  });

  group('UpdateDialog Widget Tests', () {
    testWidgets('shows Check Again when release has no APK asset yet', (WidgetTester tester) async {
      const infoWithoutApk = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.0.0',
        latestVersion: 'v1.0.1',
        releaseName: 'v1.0.1',
        releaseNotes: 'Notes',
        apkDownloadUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              initialInfo: infoWithoutApk,
              updateManager: _FakeUpdateManager(),
            ),
          ),
        ),
      );

      expect(find.text('Check Again'), findsOneWidget);
      expect(find.text('Update Now'), findsNothing);
    });

    testWidgets('recovers from permission_required and auto-launches installer on resume', (WidgetTester tester) async {
      final fakeManager = _FakeUpdateManager(
        nextInstallStatus: InstallStatus.permissionRequired,
        installPermissionAllowed: false,
      );
      const info = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.0.0',
        latestVersion: 'v1.0.1',
        releaseName: 'v1.0.1',
        releaseNotes: 'Fixes',
        apkDownloadUrl: 'https://github.com/example/recipe-app-release.apk',
        apkSizeBytes: 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              initialInfo: info,
              updateManager: fakeManager,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Update Now'));
      await tester.pumpAndSettle();

      // Dialog must NOT freeze on Downloading/Installing; shows Settings prompt
      expect(find.text('Open Settings'), findsOneWidget);
      expect(fakeManager.downloadCalls, 1);
      expect(fakeManager.installCalls, 1);

      // Simulate user granting permission in Android Settings and returning to app
      fakeManager.installPermissionAllowed = true;
      fakeManager.nextInstallStatus = InstallStatus.launched;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Installer auto-launched without re-downloading!
      expect(fakeManager.downloadCalls, 1);
      expect(fakeManager.installCalls, 2);
      expect(find.text('Install Again'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
