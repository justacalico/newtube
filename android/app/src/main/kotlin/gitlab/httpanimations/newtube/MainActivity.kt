package gitlab.httpanimations.newtube

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "newtube/pip",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> {
                    val ok = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        enterPictureInPictureMode(
                            PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build(),
                        )
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }
}
