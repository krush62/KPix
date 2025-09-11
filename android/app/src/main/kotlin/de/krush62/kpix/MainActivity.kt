package de.krush62.kpix

//import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Bundle
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
                else -> result.notImplemented()
            }
        }
        flutterEngine.plugins.add(MediaScanner())
    }

    private fun handleSendFile(intent: Intent) {
        val fileUri: Uri? = intent.data
        if (fileUri != null) {
            val file = File(fileUri.path ?: "")
            sharedFilePath = file.absolutePath
        }
    }
}
