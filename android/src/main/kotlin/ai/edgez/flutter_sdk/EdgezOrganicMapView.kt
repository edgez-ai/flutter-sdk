package ai.edgez.flutter_sdk

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import androidx.lifecycle.LifecycleOwner
import app.organicmaps.sdk.Framework
import app.organicmaps.sdk.MapController
import app.organicmaps.sdk.MapRenderingListener
import app.organicmaps.sdk.MapView
import app.organicmaps.sdk.OrganicMaps
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.Locale

internal class EdgezOrganicMapViewFactory(
    private val messenger: BinaryMessenger,
    applicationContext: Context,
    private val activityProvider: () -> Activity?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    companion object {
        const val VIEW_TYPE = "edgez_flutter_sdk/organic_map"
    }

    private val engine = EdgezOrganicMapsEngine(applicationContext)

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        EdgezOrganicMapView(
            context = context,
            viewId = viewId,
            creationParams = args as? Map<*, *> ?: emptyMap<Any, Any>(),
            messenger = messenger,
            engine = engine,
            lifecycleOwner = activityProvider() as? LifecycleOwner,
        )
}

private class EdgezOrganicMapsEngine(context: Context) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val callbacks = mutableListOf<Pair<() -> Unit, (Throwable) -> Unit>>()
    private var initializing = false

    val organicMaps: OrganicMaps

    init {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode
        }
        organicMaps = OrganicMaps(
            context.applicationContext,
            "edgez-flutter",
            context.packageName,
            versionCode,
            packageInfo.versionName ?: "0.0.0",
        )
    }

    @Synchronized
    fun initialize(onReady: () -> Unit, onError: (Throwable) -> Unit) {
        if (organicMaps.arePlatformAndCoreInitialized()) {
            mainHandler.post(onReady)
            return
        }
        callbacks += onReady to onError
        if (initializing) return
        initializing = true
        try {
            val started = organicMaps.init { finishInitialization() }
            if (!started && organicMaps.arePlatformAndCoreInitialized()) finishInitialization()
        } catch (error: Throwable) {
            failInitialization(error)
        }
    }

    private fun finishInitialization() {
        mainHandler.post {
            val readyCallbacks = synchronized(this) {
                initializing = false
                callbacks.toList().also { callbacks.clear() }
            }
            readyCallbacks.forEach { it.first() }
        }
    }

    private fun failInitialization(error: Throwable) {
        mainHandler.post {
            val failedCallbacks = synchronized(this) {
                initializing = false
                callbacks.toList().also { callbacks.clear() }
            }
            failedCallbacks.forEach { it.second(error) }
        }
    }
}

private data class EdgezNativeMapNode(
    val id: String,
    val label: String,
    val latitude: Double,
    val longitude: Double,
    val marker: String,
)

private class EdgezOrganicMapView(
    context: Context,
    viewId: Int,
    creationParams: Map<*, *>,
    messenger: BinaryMessenger,
    private val engine: EdgezOrganicMapsEngine,
    private val lifecycleOwner: LifecycleOwner?,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val root = FrameLayout(context)
    private val status = TextView(context)
    private val channel = MethodChannel(messenger, "edgez_flutter_sdk/organic_map_$viewId")
    private var mapController: MapController? = null
    private var disposed = false
    private var nodes = parseNodes(creationParams["nodes"])
    private var centerLatitude = number(creationParams["centerLatitude"]) ?: 59.3293
    private var centerLongitude = number(creationParams["centerLongitude"]) ?: 18.0686
    private var zoom = (creationParams["zoom"] as? Number)?.toInt()?.coerceIn(1, 20) ?: 12

    init {
        status.apply {
            text = "Starting offline map…"
            setTextColor(Color.WHITE)
            textSize = 15f
            gravity = Gravity.CENTER
            setPadding(24, 16, 24, 16)
            setBackgroundColor(0xCC1B1B1B.toInt())
        }
        root.addView(
            status,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.TOP,
            ),
        )
        channel.setMethodCallHandler(this)
        engine.initialize(::createMap, ::showError)
    }

    override fun getView(): View = root

    override fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        mapController?.let { controller ->
            lifecycleOwner?.let { owner ->
                owner.lifecycle.removeObserver(controller)
                controller.onDestroy(owner)
            }
        }
        mapController = null
        root.removeAllViews()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateNodes" -> {
                nodes = parseNodes(call.argument<Any>("nodes"))
                renderNodes(recenter = false)
                result.success(null)
            }
            "setCamera" -> {
                centerLatitude = call.argument<Number>("latitude")?.toDouble() ?: centerLatitude
                centerLongitude = call.argument<Number>("longitude")?.toDouble() ?: centerLongitude
                zoom = call.argument<Number>("zoom")?.toInt()?.coerceIn(1, 20) ?: zoom
                moveCamera()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun createMap() {
        if (disposed || mapController != null) return
        val mapView = MapView(root.context)
        root.addView(
            mapView,
            0,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        status.text = "Creating renderer…"
        mapController = MapController(
            mapView,
            engine.organicMaps.locationHelper,
            object : MapRenderingListener {
                override fun onRenderingCreated() {
                    root.post { status.text = "Rendering offline map…" }
                }

                override fun onRenderingRestored() {
                    root.post { renderNodes(recenter = true) }
                }

                override fun onRenderingInitializationFinished() {
                    root.post { renderNodes(recenter = true) }
                }
            },
            { root.post { showError(IllegalStateException("Map rendering is not supported")) } },
            false,
        )
        lifecycleOwner?.lifecycle?.addObserver(mapController!!)
    }

    private fun renderNodes(recenter: Boolean) {
        val controller = mapController ?: return
        if (!controller.isRenderingActive()) return
        if (recenter) moveCamera()
        Framework.nativeClearApiPoints()
        if (nodes.isNotEmpty()) {
            Framework.nativeParseAndSetApiUrl(markerUrl(nodes))
            Framework.nativeSetApiPointsFromUrl()
        }
        controller.updateCompassOffset(0, 0)
        controller.view.postInvalidate()
        status.visibility = View.GONE
    }

    private fun moveCamera() {
        val controller = mapController ?: return
        if (!controller.isRenderingActive()) return
        Framework.nativeStopLocationFollow()
        Framework.nativeZoomToPoint(centerLatitude, centerLongitude, zoom, false)
    }

    private fun showError(error: Throwable) {
        if (disposed) return
        status.visibility = View.VISIBLE
        status.text = "Offline map unavailable: ${error.message ?: error.javaClass.simpleName}"
    }

    private fun markerUrl(items: List<EdgezNativeMapNode>): String = buildString {
        append("om://map?")
        items.forEachIndexed { index, node ->
            if (index > 0) append('&')
            append("ll=")
            append(String.format(Locale.US, "%.7f,%.7f", node.latitude, node.longitude))
            append("&n=").append(Uri.encode(node.label))
            append("&id=").append(Uri.encode(node.id))
            append("&s=placemark-").append(markerStyle(node.marker))
        }
    }

    private fun markerStyle(marker: String): String = when (marker.lowercase(Locale.US)) {
        "teal" -> "green"
        "gray", "grey" -> "blue"
        "red", "green", "orange", "purple", "blue", "brown", "pink", "yellow" ->
            marker.lowercase(Locale.US)
        else -> "blue"
    }

    private fun parseNodes(value: Any?): List<EdgezNativeMapNode> =
        (value as? List<*>)?.mapNotNull { raw ->
            val map = raw as? Map<*, *> ?: return@mapNotNull null
            val latitude = number(map["latitude"]) ?: return@mapNotNull null
            val longitude = number(map["longitude"]) ?: return@mapNotNull null
            if (latitude !in -90.0..90.0 || longitude !in -180.0..180.0) return@mapNotNull null
            EdgezNativeMapNode(
                id = map["id"]?.toString().orEmpty(),
                label = map["label"]?.toString().orEmpty(),
                latitude = latitude,
                longitude = longitude,
                marker = map["marker"]?.toString() ?: "blue",
            )
        } ?: emptyList()

    private fun number(value: Any?): Double? = (value as? Number)?.toDouble()
}
