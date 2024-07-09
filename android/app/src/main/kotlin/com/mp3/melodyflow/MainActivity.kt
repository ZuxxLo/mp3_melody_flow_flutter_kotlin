package com.mp3.melodyflow

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {

    companion object {
        private const val REQUEST_READ_EXTERNAL_STORAGE = 123
    }

    private val CHANNEL = "music_player"
    private val mp3FilesList = mutableListOf<String>()
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "passTrackNameToKotlin" -> {

                    val trackName = call.argument<String>("trackName")
                    val isPlayingbool = call.argument<Boolean>("isPlayingbool")

                    sendBroadcastToService(trackName, isPlayingbool)
                }
                "getMp3Files" -> {
                    startService(Intent(this, MyService::class.java))

                    result.success(mp3FilesList)
                }
                "getNotificationActionStream" -> {
                    result.success(actionPerformed)
                }
                "StartService" -> {
                    startService(Intent(this, MyService::class.java))
                    result.success("Started!")
                }
                "StopService" -> {
                    stopService(Intent(this, MyService::class.java))
                }
                else -> result.notImplemented()
            }
        }
    }

    private val broadcastAction = "MainActivityToService"

    private fun sendBroadcastToService(value: String?, isPlayingbool: Boolean?) {
        val intent = Intent(broadcastAction)
        intent.putExtra("TRACK_NAME", value)
        intent.putExtra("IS_PLAYING_BOOL", isPlayingbool)

        println("Sent broadcast")

        sendBroadcast(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        getMp3Files()
        registerReceiver(serviceReceiver, IntentFilter("NotificationActionBroadcast"))

        // registerReceiver(resultReceiver, IntentFilter("updateUI"))

    }

    override fun onDestroy() {
        stopService(Intent(this, MyService::class.java))
        unregisterReceiver(serviceReceiver)

        super.onDestroy()
    }

    var actionPerformed: String? = null

    private val serviceReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {

                    if (intent?.action == "NotificationActionBroadcast") {
                        // isFlashlightOn = intent.getBooleanExtra("resultValue", false)
                        actionPerformed = intent.getStringExtra("ACTION_PERFORMED")
                        updateFlutter(actionPerformed)

                        // Handle the received proximityData here
                    }
                }
            }

    private fun updateFlutter(actionPerformed: String?) {
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        binaryMessenger?.let {
            val channel = MethodChannel(it, CHANNEL)
            channel.invokeMethod(
                    "updateActionPerformed",
                    mapOf("actionPerformed" to actionPerformed)
            )
        }
    }
    private fun getMp3Files(directory: File) {
        // val audioExtensions = setOf("mp3", "m4a", "wav", "flac")
        // if (file.isFile && audioExtensions.contains(file.extension.lowercase()))
        val files = directory.listFiles()
        files?.forEach { file ->
            if (file.isFile && file.extension.equals("mp3", ignoreCase = true)) {
                mp3FilesList.add(file.absolutePath)
            } else if (file.isDirectory) {
                getMp3Files(file)
            }
        }
    }

    private fun getMp3Files() {
        val permission = Manifest.permission.READ_EXTERNAL_STORAGE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED
        ) {
            // Request the permission
            requestPermissions(arrayOf(permission), REQUEST_READ_EXTERNAL_STORAGE)
        } else {
            // Permission already granted, proceed with fetching MP3 files
            // Toast.makeText(this, "Starting.", Toast.LENGTH_SHORT).show()
            val context = applicationContext
            GlobalScope.launch(Dispatchers.IO) {
                val rootFolder = File("/storage/emulated/0/")
                mp3FilesList.clear()
                getMp3Files(rootFolder)
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Fetching mp3 files in coroutines.", Toast.LENGTH_SHORT)
                            .show()
                }
            }

            // You can handle the result here as needed
        }
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_READ_EXTERNAL_STORAGE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, proceed to fetch MP3 files
                val rootFolder = File("/storage/emulated/0/")
                mp3FilesList.clear()
                getMp3Files(rootFolder)

                actionPerformed = "ALLOWED_TO_FIND_MP3_FILES"
                updateFlutter(actionPerformed)
            } else {
                // Permission denied, inform the user
                Toast.makeText(
                                this,
                                "Permission denied. Cannot access MP3 files.",
                                Toast.LENGTH_SHORT
                        )
                        .show()
                openAppSettings()
            }
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", packageName, null)
        intent.data = uri
        startActivity(intent)
        getMp3Files()
    }
}
