package de.krush62.kpix

//import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import android.view.MotionEvent
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.net.Uri
import java.io.File
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {

    private var sharedFileUri: Uri? = null
    private val CHANNEL = "app.channel.shared.data"
    private val STYLUS_CHANNEL = "app.channel.stylus"
    private var stylusChannel: MethodChannel? = null
    private var sharedDataChannel: MethodChannel? = null
    private val fileCopier = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?)
    {
        super.onCreate(savedInstanceState)
        //a restored activity or a launch from Recents carries the intent of an already opened file
        if (savedInstanceState == null && (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0)
        {
            sharedFileUri = viewedUriOf(intent)
        }
    }

    //launchMode singleTask: a file opened from another app while running arrives here instead of in a second instance
    override fun onNewIntent(intent: Intent)
    {
        super.onNewIntent(intent)
        viewedUriOf(intent)?.let { uri -> resolveFile(uri) { path -> path?.let { sharedDataChannel?.invokeMethod("openFile", it) } } }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        sharedDataChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFile" -> {
                    val uri = sharedFileUri
                    sharedFileUri = null
                    if (uri == null) result.success(null) else resolveFile(uri) { result.success(it) }
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

    private fun viewedUriOf(intent: Intent): Uri?
    {
        val uri = intent.data
        return if (Intent.ACTION_VIEW == intent.action && (uri?.scheme == "file" || uri?.scheme == "content")) uri else null
    }

    //a content URI has no file path: its file is copied to the cache under its own name, which the import keeps
    private fun resolveFile(uri: Uri, onResolved: (String?) -> Unit)
    {
        if (uri.scheme == "file")
        {
            onResolved(uri.path)
            return
        }
        fileCopier.execute {
            val path = try {
                copyToCache(uri)
            } catch (e: Exception) {
                Log.w("KPix", "Could not read the opened file $uri", e)
                null
            }
            runOnUiThread { onResolved(path) }
        }
    }

    private fun copyToCache(uri: Uri): String?
    {
        val name = File(displayNameOf(uri) ?: uri.lastPathSegment ?: return null).name
        if (name.isBlank() || name == "." || name == "..")
        {
            return null
        }
        val dir = File(cacheDir, "opened_files")
        dir.deleteRecursively()
        dir.mkdirs()
        val target = File(dir, name)
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { source -> target.outputStream().use { source.copyTo(it) } }
        return target.absolutePath
    }

    private fun displayNameOf(uri: Uri): String? = try {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getString(0) else null
        }
    } catch (e: Exception) {
        null
    }
}
