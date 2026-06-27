package com.appvora.testermandi

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val appInfoChannel = "com.appvora/app_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appInfoChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAppInstalled" -> {
                        val packageId = call.argument<String>("packageId")
                        if (packageId.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "packageId is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getApplicationInfo(
                                    packageId,
                                    PackageManager.ApplicationInfoFlags.of(0L)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getApplicationInfo(packageId, 0)
                            }
                            val appName = packageManager.getApplicationLabel(appInfo).toString()

                            // Extract icon as base64 PNG
                            val iconBase64 = try {
                                val drawable = packageManager.getApplicationIcon(appInfo)
                                val bitmap = drawableToBitmap(drawable)
                                val stream = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                                Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                            } catch (_: Exception) {
                                null
                            }

                            result.success(mapOf(
                                "installed" to true,
                                "name" to appName,
                                "iconBase64" to iconBase64,
                            ))
                        } catch (e: PackageManager.NameNotFoundException) {
                            result.success(mapOf("installed" to false, "name" to null, "iconBase64" to null))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 192
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 192
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
