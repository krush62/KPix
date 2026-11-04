package de.krush62.kpix

//import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.view.MotionEvent
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.net.Uri
import java.io.File

class MainActivity: FlutterActivity() {

    private var sharedFilePath: String? = null
    private val CHANNEL = "app.channel.shared.data"
    private val STYLUS_CHANNEL = "app.channel.stylus"
    private var stylusChannel: MethodChannel? = null
    private var sharedDataChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?)
    {
        super.onCreate(savedInstanceState)
        sharedFilePath = sharedFilePathOf(intent)
    }

    //launchMode singleTask: a file opened from another app while running arrives here instead of in a second instance
    override fun onNewIntent(intent: Intent)
    {
        super.onNewIntent(intent)
        sharedFilePathOf(intent)?.let { sharedDataChannel?.invokeMethod("openFile", it) }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        sharedDataChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFile" -> {
                    result.success(sharedFilePath)
                    sharedFilePath = null
                }
                "hasAllFilesAccess" -> {
                    result.success(hasAllFilesAccess())
                }
                "openAllFilesAccessSettings" -> {
                    result.success(openAllFilesAccessSettings())
                }
                else -> result.notImplemented()
            }
        }
        flutterEngine.plugins.add(MediaScanner())
        stylusChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STYLUS_CHANNEL)
    }

    //Flutter only forwards hover moves, so stylus hover exits are sent here
    //(button events are not needed: Android drops them while hovering, pointer events carry the button state)
    override fun dispatchGenericMotionEvent(ev: MotionEvent): Boolean
    {
        val toolType = ev.getToolType(ev.actionIndex)
        if (ev.actionMasked == MotionEvent.ACTION_HOVER_EXIT && (toolType == MotionEvent.TOOL_TYPE_STYLUS || toolType == MotionEvent.TOOL_TYPE_ERASER))
        {
            stylusChannel?.invokeMethod("hoverExit", ev.eventTime)
        }
        return super.dispatchGenericMotionEvent(ev)
    }

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            // MANAGE_EXTERNAL_STORAGE does not exist below Android 11
            true
        }
    }

    private fun openAllFilesAccessSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return false
        }
        return try {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:$packageName"))
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    private fun sharedFilePathOf(intent: Intent): String? {
        val scheme = intent.scheme
        if (Intent.ACTION_VIEW != intent.action || intent.type == null || ("file" != scheme && "content" != scheme)) {
            return null
        }
        val fileUri: Uri = intent.data ?: return null
        return File(fileUri.path ?: "").absolutePath
    }
}
