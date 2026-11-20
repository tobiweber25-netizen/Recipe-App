package com.example.seasonal_prep_cook

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.seasonal_prep_cook/installer"

    private fun getInstalledPackageInfo(flags: Long = 0L): PackageInfo {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, flags.toInt())
        }
    }

    private fun getArchivePackageInfo(apkPath: String, flags: Long = 0L): PackageInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageArchiveInfo(apkPath, PackageManager.PackageInfoFlags.of(flags))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(apkPath, flags.toInt())
        }
    }

    private fun getVersionCode(pInfo: PackageInfo): Long {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            pInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            pInfo.versionCode.toLong()
        }
    }

    private fun getSignerDigests(pInfo: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signingInfo = pInfo.signingInfo ?: return emptySet()
            if (signingInfo.hasMultipleSigners()) {
                signingInfo.apkContentsSigners
            } else {
                signingInfo.signingCertificateHistory
            }
        } else {
            @Suppress("DEPRECATION")
            pInfo.signatures
        } ?: return emptySet()

        val md = MessageDigest.getInstance("SHA-256")
        return signatures.map { sig ->
            md.reset()
            md.digest(sig.toByteArray()).joinToString("") { "%02x".format(it) }
        }.toSet()
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openUnknownSourcesSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manageIntent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName")
            )
            startActivity(manageIntent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canInstallPackages" -> {
                    result.success(canInstallPackages())
                }
                "openInstallPermissionSettings" -> {
                    try {
                        openUnknownSourcesSettings()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.localizedMessage ?: "Unable to open install settings", null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrBlank()) {
                        result.error("INVALID_PATH", "APK file path is missing.", null)
                        return@setMethodCallHandler
                    }
                    val file = File(filePath)
                    if (!file.exists() || file.length() <= 0L) {
                        result.error("FILE_NOT_FOUND", "Downloaded update file was not found.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val certFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            PackageManager.GET_SIGNING_CERTIFICATES.toLong()
                        } else {
                            @Suppress("DEPRECATION")
                            PackageManager.GET_SIGNATURES.toLong()
                        }

                        val archiveInfo = getArchivePackageInfo(file.absolutePath, certFlag)
                            ?: getArchivePackageInfo(file.absolutePath, 0L)
                        if (archiveInfo == null) {
                            file.delete()
                            result.error("INVALID_APK", "Downloaded update file is corrupted or incomplete.", null)
                            return@setMethodCallHandler
                        }
                        if (archiveInfo.packageName != packageName) {
                            file.delete()
                            result.error("PACKAGE_MISMATCH", "Update package does not match this app.", null)
                            return@setMethodCallHandler
                        }

                        val installedInfo = getInstalledPackageInfo(certFlag)
                        val installedCode = getVersionCode(installedInfo)
                        val archiveCode = getVersionCode(archiveInfo)
                        if (archiveCode < installedCode) {
                            file.delete()
                            result.error(
                                "VERSION_DOWNGRADE",
                                "Update build ($archiveCode) is older than installed build ($installedCode).",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val installedSigners = getSignerDigests(installedInfo)
                        val archiveSigners = getSignerDigests(archiveInfo)
                        if (installedSigners.isNotEmpty() && archiveSigners.isNotEmpty() &&
                            installedSigners.intersect(archiveSigners).isEmpty()
                        ) {
                            file.delete()
                            result.error(
                                "SIGNATURE_MISMATCH",
                                "Update signature does not match the installed app.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        if (!canInstallPackages()) {
                            openUnknownSourcesSettings()
                            result.success(mapOf("status" to "permission_required"))
                            return@setMethodCallHandler
                        }

                        val apkUri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )

                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(installIntent)
                        result.success(mapOf("status" to "launched"))
                    } catch (e: ActivityNotFoundException) {
                        result.error("INSTALLER_UNAVAILABLE", "No Android package installer available on this device.", null)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.localizedMessage ?: "Unable to start update installer.", null)
                    }
                }
                "getAppVersion" -> {
                    try {
                        val pInfo = getInstalledPackageInfo(0L)
                        val versionName = pInfo.versionName ?: "1.0.0"
                        val versionCode = getVersionCode(pInfo)
                        result.success(mapOf("versionName" to versionName, "versionCode" to versionCode))
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.localizedMessage ?: "Unable to read app version.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
