import 'package:flutter/material.dart';
import '../services/app_update_manager.dart';
import '../utils/app_tokens.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo? initialInfo;
  final bool autoCheck;
  final AppUpdateManager? updateManager;

  const UpdateDialog({
    super.key,
    this.initialInfo,
    this.autoCheck = false,
    this.updateManager,
  });

  static Future<void> show(
    BuildContext context, {
    AppUpdateInfo? initialInfo,
    bool autoCheck = false,
    AppUpdateManager? updateManager,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateDialog(
        initialInfo: initialInfo,
        autoCheck: autoCheck,
        updateManager: updateManager,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with WidgetsBindingObserver {
  late final AppUpdateManager _updateManager;
  late final bool _ownsManager;

  bool _isChecking = false;
  bool _isDownloading = false;
  bool _isLaunchingInstaller = false;
  bool _awaitingInstallPermission = false;
  bool _installerLaunched = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedApkPath;
  String? _errorMessage;
  AppUpdateInfo? _updateInfo;
  UpdateCancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsManager = widget.updateManager == null;
    _updateManager = widget.updateManager ?? AppUpdateManager();
    _updateInfo = widget.initialInfo;
    if (_updateInfo == null || widget.autoCheck) {
      _checkForUpdates();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    if (_ownsManager) {
      _updateManager.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awaitingInstallPermission &&
        _downloadedApkPath != null &&
        !_isLaunchingInstaller) {
      _resumeInstallAfterSettings();
    }
  }

  Future<void> _resumeInstallAfterSettings() async {
    final allowed = await _updateManager.canInstallPackages();
    if (!mounted || !allowed || _downloadedApkPath == null) return;
    await _launchInstallerForPath(_downloadedApkPath!);
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _awaitingInstallPermission = false;
      _installerLaunched = false;
    });

    try {
      final info = await _updateManager.checkForUpdate();
      if (!info.hasUpdate) {
        await _updateManager.cleanupCachedApks();
      }
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = _formatError(e);
        });
      }
    }
  }

  String _formatError(Object error) {
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length);
    } else if (msg.startsWith('HttpException: ')) {
      msg = msg.substring('HttpException: '.length);
    }
    return msg;
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<void> _launchInstallerForPath(String filePath) async {
    if (_isLaunchingInstaller) return;
    setState(() {
      _isLaunchingInstaller = true;
      _errorMessage = null;
    });

    try {
      final status = await _updateManager.installApk(filePath);
      if (!mounted) return;
      setState(() {
        _isLaunchingInstaller = false;
        _isDownloading = false;
        _downloadedApkPath = filePath;
        _awaitingInstallPermission = status == InstallStatus.permissionRequired;
        _installerLaunched = status == InstallStatus.launched;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLaunchingInstaller = false;
        _isDownloading = false;
        _awaitingInstallPermission = false;
        _installerLaunched = false;
        _downloadedApkPath = null;
        _errorMessage = 'Install failed: ${_formatError(e)}';
      });
    }
  }

  Future<void> _startDownloadAndInstall() async {
    final info = _updateInfo;
    if (info == null || info.apkDownloadUrl == null) return;

    if (_downloadedApkPath != null) {
      await _launchInstallerForPath(_downloadedApkPath!);
      return;
    }

    final token = UpdateCancelToken();
    _cancelToken = token;

    setState(() {
      _isDownloading = true;
      _awaitingInstallPermission = false;
      _installerLaunched = false;
      _downloadProgress = 0.0;
      _receivedBytes = 0;
      _totalBytes = info.apkSizeBytes ?? 0;
      _errorMessage = null;
    });

    try {
      final outcome = await _updateManager.downloadAndInstall(
        downloadUrl: info.apkDownloadUrl!,
        versionTag: info.latestVersion,
        expectedSizeBytes: info.apkSizeBytes,
        cancelToken: token,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _receivedBytes = received;
              _totalBytes = total;
            });
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadedApkPath = outcome.apkFilePath;
        _awaitingInstallPermission = outcome.status == InstallStatus.permissionRequired;
        _installerLaunched = outcome.status == InstallStatus.launched;
      });
    } on UpdateCancelledException {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _receivedBytes = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _awaitingInstallPermission = false;
          _installerLaunched = false;
          _errorMessage = 'Update failed: ${_formatError(e)}';
        });
      }
    }
  }

  Future<void> _openInstallSettings() async {
    try {
      await _updateManager.openInstallPermissionSettings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not open settings: ${_formatError(e)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDownloading,
      child: Dialog(
        backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(
            color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
            width: 1.0,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLg,
          vertical: AppTokens.spaceXl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceLg),
            child: _buildDialogContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context, bool isDark) {
    if (_isChecking) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.spaceMd),
          CircularProgressIndicator(
            color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
          ),
          const SizedBox(height: AppTokens.spaceLg),
          Text(
            'Checking for updates...',
            style: AppTokens.display(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spaceSm),
          Text(
            'Connecting to GitHub Releases',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],
      );
    }

    if (_errorMessage != null) {
      final hasKnownUpdate = _updateInfo?.hasUpdate == true && _updateInfo?.apkDownloadUrl != null;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                decoration: BoxDecoration(
                  color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: isDark ? AppTokens.errorDark : AppTokens.errorLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTokens.spaceSm + AppTokens.spaceXs),
              Expanded(
                child: Text(
                  hasKnownUpdate ? 'Update Failed' : 'Update Check Failed',
                  style: AppTokens.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMd),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spaceLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceSm),
              ElevatedButton(
                onPressed: hasKnownUpdate ? _startDownloadAndInstall : _checkForUpdates,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      );
    }

    final info = _updateInfo;
    if (info == null || !info.hasUpdate) {
      final currentVer = AppUpdateManager.formatVersionLabel(info?.currentVersion ?? '1.0.0');
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                decoration: BoxDecoration(
                  color: isDark ? AppTokens.accentMintTintDark : AppTokens.accentMintTintLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTokens.spaceSm + AppTokens.spaceXs),
              Expanded(
                child: Text(
                  "You're Up to Date",
                  style: AppTokens.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMd),
          Text(
            'Version $currentVer is the latest version installed.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spaceLg),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      );
    }

    final hasDownloadAsset = info.apkDownloadUrl != null && info.apkDownloadUrl!.isNotEmpty;

    // New version available!
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm + AppTokens.spaceXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Available',
                    style: AppTokens.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXs / 2),
                  Text(
                    info.releaseName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceMd),

        // Version badge and file size
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMd,
            vertical: AppTokens.spaceSm + AppTokens.spaceXs / 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(
              color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppUpdateManager.formatVersionLabel(info.currentVersion),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTokens.spaceXs),
                    child: Icon(Icons.arrow_forward_rounded, size: 14),
                  ),
                  Text(
                    AppUpdateManager.formatVersionLabel(info.latestVersion),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                    ),
                  ),
                ],
              ),
              if (info.formattedSize.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceSm,
                    vertical: AppTokens.spaceXs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Text(
                    info.formattedSize,
                    style: AppTokens.kicker(
                      fontSize: 10,
                      color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppTokens.spaceMd),

        // Release notes
        if (info.releaseNotes.isNotEmpty) ...[
          Text(
            'WHAT\'S NEW',
            style: AppTokens.kicker(
              fontSize: 10.5,
              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            padding: const EdgeInsets.all(AppTokens.spaceSm + AppTokens.spaceXs),
            decoration: BoxDecoration(
              color: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: SingleChildScrollView(
              child: Text(
                info.releaseNotes,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],

        if (!hasDownloadAsset) ...[
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceSm + AppTokens.spaceXs),
            decoration: BoxDecoration(
              color: AppTokens.sandTint(isDark),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: AppTokens.sandBorder(isDark)),
            ),
            child: Text(
              'The update file is still being prepared on GitHub. Please check again in a minute.',
              style: AppTokens.sansBody(
                fontSize: 12.5,
                color: AppTokens.textPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],

        if (_awaitingInstallPermission) ...[
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceSm + AppTokens.spaceXs),
            decoration: BoxDecoration(
              color: AppTokens.sandTint(isDark),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: AppTokens.sandBorder(isDark),
                width: 1.0,
              ),
            ),
            child: Text(
              'Enable "Install unknown apps" in Android Settings and return here — the update will start automatically.',
              style: AppTokens.sansBody(
                fontSize: 12.5,
                height: 1.4,
                color: AppTokens.textPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],

        if (_installerLaunched && !_isDownloading && !_awaitingInstallPermission) ...[
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceSm + AppTokens.spaceXs),
            decoration: BoxDecoration(
              color: AppTokens.primaryContainer(isDark),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: AppTokens.primary(isDark).withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Text(
              'Installer opened. Confirm "Update" in the Android prompt, or tap Install Again if you dismissed it.',
              style: AppTokens.sansBody(
                fontSize: 12.5,
                height: 1.4,
                color: AppTokens.textPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],

        // Download Progress
        if (_isDownloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            child: LinearProgressIndicator(
              value: _downloadProgress > 0.0 ? _downloadProgress : null,
              backgroundColor: isDark ? AppTokens.borderDark : AppTokens.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTokens.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _downloadProgress >= 1.0 ? 'Opening installer...' : 'Downloading update...',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                ),
              ),
              Text(
                _totalBytes > 0
                    ? '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB (${(_downloadProgress * 100).toInt()}%)'
                    : '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: AppTokens.kicker(
                  fontSize: 10.5,
                  color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],

        // Action Buttons
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceSm,
          children: [
            if (_isDownloading)
              TextButton(
                onPressed: _cancelDownload,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  _installerLaunched ? 'Close' : 'Later',
                  style: TextStyle(
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                ),
              ),
            if (!hasDownloadAsset)
              ElevatedButton(
                onPressed: _checkForUpdates,
                child: const Text('Check Again'),
              )
            else if (_awaitingInstallPermission)
              ElevatedButton.icon(
                onPressed: _openInstallSettings,
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Open Settings'),
              )
            else
              ElevatedButton.icon(
                onPressed: (_isDownloading || _isLaunchingInstaller) ? null : _startDownloadAndInstall,
                icon: Icon(
                  _isDownloading || _isLaunchingInstaller
                      ? Icons.hourglass_top_rounded
                      : (_downloadedApkPath != null ? Icons.install_mobile_rounded : Icons.cloud_download_rounded),
                  size: 18,
                ),
                label: Text(
                  _isDownloading
                      ? 'Downloading...'
                      : (_isLaunchingInstaller
                          ? 'Opening...'
                          : (_installerLaunched
                              ? 'Install Again'
                              : (_downloadedApkPath != null ? 'Install Update' : 'Update Now'))),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
