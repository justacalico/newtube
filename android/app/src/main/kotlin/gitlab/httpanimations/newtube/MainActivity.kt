package gitlab.httpanimations.newtube

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pipChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "newtube/pip",
            ).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "enterPip" -> result.success(enterPip())
                        else -> result.notImplemented()
                    }
                }
            }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "newtube/brightness",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    val value = window.attributes.screenBrightness
                    result.success(if (value < 0f) 1.0 else value.toDouble())
                }
                "setBrightness" -> {
                    val value = (call.arguments as? Number)?.toFloat() ?: 1.0f
                    val lp = window.attributes
                    lp.screenBrightness = value.coerceIn(0f, 1f)
                    window.attributes = lp
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("pipModeChanged", isInPictureInPictureMode)
    }

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            return false
        }
        return try {
            enterPictureInPictureMode(
                PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .build(),
            )
        } catch (e: Exception) {
            false
        }
    }
}
