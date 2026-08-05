package ai.edgez.flutter_sdk

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class EdgezBleForegroundService : Service() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val deviceLabel = intent?.getStringExtra(EXTRA_DEVICE_LABEL).orEmpty()
        startForeground(
            BACKGROUND_NOTIFICATION_ID,
            buildBackgroundNotification(this, deviceLabel),
        )
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val ACTION_START = "ai.edgez.flutter_sdk.action.START_BLE_BACKGROUND"
        private const val EXTRA_DEVICE_LABEL = "deviceLabel"
        private const val BACKGROUND_CHANNEL_ID = "edgez_ble_connection"
        private const val MESSAGE_CHANNEL_ID = "edgez_messages"
        private const val CALL_CHANNEL_ID = "edgez_calls"
        private const val BACKGROUND_NOTIFICATION_ID = 0xED01
        private const val CALL_NOTIFICATION_ID = 0xED02

        fun start(context: Context, deviceLabel: String) {
            createNotificationChannels(context)
            val intent = Intent(context, EdgezBleForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_DEVICE_LABEL, deviceLabel)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, EdgezBleForegroundService::class.java))
            NotificationManagerCompat.from(context).cancel(BACKGROUND_NOTIFICATION_ID)
        }

        fun notificationsAllowed(context: Context): Boolean {
            if (Build.VERSION.SDK_INT >= 33 &&
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return false
            }
            return NotificationManagerCompat.from(context).areNotificationsEnabled()
        }

        fun showMessage(
            context: Context,
            sender: String,
            body: String,
            nodeNum: Long,
            messageId: String,
        ): Boolean {
            if (!notificationsAllowed(context)) return false
            createNotificationChannels(context)
            val senderName = sender.ifBlank { "EdgeZ contact" }
            val person = androidx.core.app.Person.Builder()
                .setName(senderName)
                .setKey(nodeNum.toString())
                .build()
            val style = NotificationCompat.MessagingStyle(person)
                .setConversationTitle(senderName)
                .addMessage(body.ifBlank { "New message" }, System.currentTimeMillis(), person)
            val notification = NotificationCompat.Builder(context, MESSAGE_CHANNEL_ID)
                .setSmallIcon(notificationIcon(context))
                .setContentTitle(senderName)
                .setContentText(body.ifBlank { "New message" })
                .setStyle(style)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setAutoCancel(true)
                .setContentIntent(activityPendingIntent(context, messageUri(nodeNum), messageId.hashCode()))
                .build()
            NotificationManagerCompat.from(context).notify(messageId.ifBlank { nodeNum.toString() }, nodeNum.hashCode(), notification)
            return true
        }

        fun showIncomingCall(
            context: Context,
            caller: String,
            nodeNum: Long,
            callId: Long,
        ): Boolean {
            if (!notificationsAllowed(context)) return false
            createNotificationChannels(context)
            val callerName = caller.ifBlank { "EdgeZ caller" }
            val contentIntent = activityPendingIntent(
                context,
                callUri(nodeNum, callId, "open"),
                requestCode(callId, 0),
            )
            val answerIntent = activityPendingIntent(
                context,
                callUri(nodeNum, callId, "answer"),
                requestCode(callId, 1),
            )
            val declineIntent = activityPendingIntent(
                context,
                callUri(nodeNum, callId, "decline"),
                requestCode(callId, 2),
            )
            val builder = NotificationCompat.Builder(context, CALL_CHANNEL_ID)
                .setSmallIcon(notificationIcon(context))
                .setContentTitle(callerName)
                .setContentText("Incoming EdgeZ voice call")
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setTimeoutAfter(60_000L)
                .setContentIntent(contentIntent)
                .setFullScreenIntent(contentIntent, true)

            val person = androidx.core.app.Person.Builder()
                .setName(callerName)
                .setImportant(true)
                .build()
            builder.setStyle(
                NotificationCompat.CallStyle.forIncomingCall(
                    person,
                    declineIntent,
                    answerIntent,
                ),
            )
            NotificationManagerCompat.from(context).notify(CALL_NOTIFICATION_ID, builder.build())
            return true
        }

        fun cancelIncomingCall(context: Context) {
            NotificationManagerCompat.from(context).cancel(CALL_NOTIFICATION_ID)
        }

        private fun buildBackgroundNotification(context: Context, deviceLabel: String): Notification {
            val detail = if (deviceLabel.isBlank()) {
                "Listening for EdgeZ messages and calls"
            } else {
                "Connected to $deviceLabel"
            }
            return NotificationCompat.Builder(context, BACKGROUND_CHANNEL_ID)
                .setSmallIcon(notificationIcon(context))
                .setContentTitle("EdgeZ BLE active")
                .setContentText(detail)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setOngoing(true)
                .setContentIntent(activityPendingIntent(context, Uri.parse("edgez://open"), 0))
                .build()
        }

        private fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT < 26) return
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannels(
                listOf(
                    NotificationChannel(
                        BACKGROUND_CHANNEL_ID,
                        "BLE connection",
                        NotificationManager.IMPORTANCE_LOW,
                    ).apply {
                        description = "Keeps the EdgeZ BLE connection active in the background"
                        setShowBadge(false)
                    },
                    NotificationChannel(
                        MESSAGE_CHANNEL_ID,
                        "Messages",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Incoming EdgeZ chat and voice messages"
                    },
                    NotificationChannel(
                        CALL_CHANNEL_ID,
                        "Incoming calls",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Incoming EdgeZ voice calls"
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                        enableVibration(true)
                        lightColor = Color.GREEN
                        enableLights(true)
                    },
                ),
            )
        }

        private fun activityPendingIntent(context: Context, uri: Uri, requestCode: Int): PendingIntent {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(Intent.ACTION_VIEW)
            launchIntent.apply {
                action = Intent.ACTION_VIEW
                data = uri
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun messageUri(nodeNum: Long): Uri = Uri.Builder()
            .scheme("edgez")
            .authority("message")
            .appendQueryParameter("node", nodeNum.toString())
            .build()

        private fun callUri(nodeNum: Long, callId: Long, action: String): Uri = Uri.Builder()
            .scheme("edgez")
            .authority("call")
            .appendQueryParameter("node", nodeNum.toString())
            .appendQueryParameter("call", callId.toString())
            .appendQueryParameter("action", action)
            .build()

        private fun requestCode(callId: Long, action: Int): Int =
            (callId xor (callId ushr 32)).toInt() * 31 + action

        private fun notificationIcon(context: Context): Int =
            context.applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_sys_data_bluetooth
    }
}
