import 'package:flutter/material.dart';
import '../services/app_update_manager.dart';
import '../utils/app_tokens.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo? initialInfo;
  final bool autoCheck;

  const UpdateDialog({
    super.key,
    this.initialInfo,
    this.autoCheck = false,
  });

  static Future<void> show(
    BuildContext context, {
    AppUpdateInfo? initialInfo,
    bool autoCheck = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateDialog(
        initialInfo: initialInfo,
        autoCheck: autoCheck,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final AppUpdateManager _updateManager = AppUpdateManager();

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  AppUpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _updateInfo = widget.initialInfo;
    if (_updateInfo == null || widget.autoCheck) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final info = await _updateManager.checkForUpdate();
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
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _startDownloadAndInstall() async {
    final info = _updateInfo;
    if (info == null || info.apkDownloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      await _updateManager.downloadAndInstall(
        downloadUrl: info.apkDownloadUrl!,
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
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
                  'Update Check Failed',
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
                onPressed: _checkForUpdates,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      );
    }

    final info = _updateInfo;
    if (info == null || !info.hasUpdate) {
      final currentVer = info?.currentVersion ?? '1.0.0';
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
                    'v${info.currentVersion}',
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
                    info.latestVersion,
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
                'Downloading APK...',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_isDownloading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                ),
              ),
            const SizedBox(width: AppTokens.spaceSm),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownloadAndInstall,
              icon: Icon(
                _isDownloading ? Icons.hourglass_top_rounded : Icons.cloud_download_rounded,
                size: 18,
              ),
              label: Text(_isDownloading ? 'Installing...' : 'Update Now'),
            ),
          ],
        ),
      ],
    );
  }
}
