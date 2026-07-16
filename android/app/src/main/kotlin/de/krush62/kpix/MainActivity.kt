package de.krush62.kpix

//import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
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

    override fun onCreate(savedInstanceState: Bundle?)
    {
        super.onCreate(savedInstanceState)
        val intent = intent
        val action = intent.action
        val type = intent.type
        val scheme = intent.scheme

        if (Intent.ACTION_VIEW == action && type != null && scheme != null)
        {
            if ("file" == scheme || "content" == scheme)
            {
                println("KPRIX: HANDLE INTENT")
                handleSendFile(intent)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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

    private fun handleSendFile(intent: Intent) {
        val fileUri: Uri? = intent.data
        if (fileUri != null) {
            val file = File(fileUri.path ?: "")
            sharedFilePath = file.absolutePath
        }
    }
}
