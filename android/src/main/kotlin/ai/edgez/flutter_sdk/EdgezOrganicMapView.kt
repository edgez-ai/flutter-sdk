package ai.edgez.flutter_sdk

import android.Manifest
import android.app.Activity
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.Surface
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import app.organicmaps.sdk.Framework
import app.organicmaps.sdk.MapController
import app.organicmaps.sdk.MapRenderingListener
import app.organicmaps.sdk.MapView
import app.organicmaps.sdk.OrganicMaps
import app.organicmaps.sdk.downloader.CountryItem
import app.organicmaps.sdk.downloader.MapManager
import app.organicmaps.sdk.util.ConnectionState
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
    private val locationPermissionRequester: ((Boolean) -> Unit) -> Unit,
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
            activity = activityProvider(),
            locationPermissionRequester = locationPermissionRequester,
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
    private val activity: Activity?,
    private val locationPermissionRequester: ((Boolean) -> Unit) -> Unit,
) : PlatformView, MethodChannel.MethodCallHandler, DefaultLifecycleObserver {
    private val root = FrameLayout(context)
    private val status = TextView(context)
    private val channel = MethodChannel(messenger, "edgez_flutter_sdk/organic_map_$viewId")
    private val lifecycleOwner = activity as? LifecycleOwner
    private var mapController: MapController? = null
    private var disposed = false
    private var renderingReady = false
    private var initialCameraApplied = false
    private var locationPermissionGranted = false
    private val enableMapDownloads = creationParams["enableMapDownloads"] as? Boolean ?: false
    private val requestedRegions = mutableSetOf<String>()
    private val dismissedRegions = mutableSetOf<String>()
    private var pendingRegionId: String? = null
    private var storageCallbackSlot: Int? = null
    private var nodes = parseNodes(creationParams["nodes"])
    private var centerLatitude = number(creationParams["centerLatitude"])
    private var centerLongitude = number(creationParams["centerLongitude"])
    private var zoom = (creationParams["zoom"] as? Number)?.toInt()?.coerceIn(1, 20) ?: 9
    private val locationPoll = object : Runnable {
        override fun run() {
            if (disposed || !locationPermissionGranted) return
            applyInitialCamera()
            if (!initialCameraApplied) root.postDelayed(this, PHONE_LOCATION_REFRESH_MS)
        }
    }
    private val regionCheck = object : Runnable {
        override fun run() {
            if (disposed || !enableMapDownloads) return
            refreshDownloadPrompt()
            root.postDelayed(this, REGION_AUTOCACHE_INTERVAL_MS)
        }
    }

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
        lifecycleOwner?.lifecycle?.addObserver(this)
        engine.initialize(
            onReady = {
                ConnectionState.INSTANCE.initialize(root.context.applicationContext)
                runCatching { Framework.nativeRestoreDownloadQueue() }
                createMap()
                locationPermissionRequester(::onLocationPermissionResult)
            },
            onError = ::showError,
        )
    }

    override fun getView(): View = root

    override fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        root.removeCallbacks(locationPoll)
        root.removeCallbacks(regionCheck)
        storageCallbackSlot?.let(MapManager::nativeUnsubscribe)
        storageCallbackSlot = null
        engine.organicMaps.locationHelper.stop()
        lifecycleOwner?.lifecycle?.removeObserver(this)
        mapController?.let { controller ->
            lifecycleOwner?.let { owner ->
                owner.lifecycle.removeObserver(controller)
                controller.onDestroy(owner)
            }
        }
        mapController = null
        root.removeAllViews()
    }

    override fun onStart(owner: LifecycleOwner) {
        startLocationIfReady()
    }

    override fun onStop(owner: LifecycleOwner) {
        root.removeCallbacks(locationPoll)
        engine.organicMaps.locationHelper.stop()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateNodes" -> {
                nodes = parseNodes(call.argument<Any>("nodes"))
                renderNodes()
                applyInitialCamera()
                result.success(null)
            }
            "setCamera" -> {
                centerLatitude = call.argument<Number>("latitude")?.toDouble() ?: centerLatitude
                centerLongitude = call.argument<Number>("longitude")?.toDouble() ?: centerLongitude
                zoom = call.argument<Number>("zoom")?.toInt()?.coerceIn(1, 20) ?: zoom
                moveCamera()
                result.success(null)
            }
            "downloadRegion" -> {
                val regionId = call.argument<String>("regionId")
                if (regionId.isNullOrBlank()) {
                    result.error("invalid_region", "A map region is required", null)
                } else {
                    startRegionDownload(regionId)
                    result.success(null)
                }
            }
            "dismissDownloadRegion" -> {
                call.argument<String>("regionId")?.let(dismissedRegions::add)
                pendingRegionId = null
                result.success(null)
            }
            "getCamera" -> result.success(readCurrentCamera())
            else -> result.notImplemented()
        }
    }

    private fun createMap() {
        if (disposed || mapController != null) return
        val mapView = MapView(root.context)
        mapView.setOnTouchListener { _, event ->
            if (event.actionMasked == MotionEvent.ACTION_UP ||
                event.actionMasked == MotionEvent.ACTION_CANCEL
            ) {
                root.postDelayed(
                    {
                        notifyCameraChanged()
                        if (enableMapDownloads) refreshDownloadPrompt()
                    },
                    DOWNLOAD_PROMPT_GESTURE_DELAY_MS,
                )
            }
            false
        }
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
                    root.post { onRenderingReady() }
                }

                override fun onRenderingInitializationFinished() {
                    root.post { onRenderingReady() }
                }
            },
            { root.post { showError(IllegalStateException("Map rendering is not supported")) } },
            false,
        )
        lifecycleOwner?.lifecycle?.addObserver(mapController!!)
        startLocationIfReady()
    }

    private fun onLocationPermissionResult(granted: Boolean) {
        if (disposed) return
        locationPermissionGranted = granted
        startLocationIfReady()
        applyInitialCamera()
    }

    @Suppress("DEPRECATION")
    private fun startLocationIfReady() {
        if (disposed || !locationPermissionGranted || mapController == null) return
        val lifecycle = lifecycleOwner?.lifecycle
        if (lifecycle != null && !lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) return
        val rotation = activity?.windowManager?.defaultDisplay?.rotation ?: Surface.ROTATION_0
        engine.organicMaps.sensorHelper.setRotation(rotation)
        engine.organicMaps.locationHelper.start()
        root.removeCallbacks(locationPoll)
        root.post(locationPoll)
    }

    private fun onRenderingReady() {
        renderingReady = true
        renderNodes()
        applyInitialCamera()
        subscribeToMapDownloads()
        if (enableMapDownloads) {
            root.removeCallbacks(regionCheck)
            root.postDelayed(regionCheck, REGION_AUTOCACHE_INITIAL_DELAY_MS)
        }
    }

    private fun renderNodes() {
        val controller = mapController ?: return
        if (!controller.isRenderingActive()) return
        Framework.nativeClearApiPoints()
        if (nodes.isNotEmpty()) {
            Framework.nativeParseAndSetApiUrl(markerUrl(nodes))
            Framework.nativeSetApiPointsFromUrl()
        }
        controller.updateCompassOffset(0, 0)
        controller.view.postInvalidate()
        status.visibility = View.GONE
    }

    private fun applyInitialCamera() {
        if (disposed || initialCameraApplied || !renderingReady) return
        val explicitLatitude = centerLatitude
        val explicitLongitude = centerLongitude
        val target = if (explicitLatitude != null && explicitLongitude != null) {
            explicitLatitude to explicitLongitude
        } else if (locationPermissionGranted) {
            currentPhoneLocation()?.let { it.latitude to it.longitude }
        } else {
            nodes.firstOrNull()?.let { it.latitude to it.longitude }
        } ?: return

        moveCamera(target.first, target.second)
        initialCameraApplied = true
        root.postDelayed(
            {
                if (!disposed && renderingReady) moveCamera(target.first, target.second)
            },
            MAP_REFRESH_DELAY_MS,
        )
    }

    private fun moveCamera() {
        val latitude = centerLatitude ?: return
        val longitude = centerLongitude ?: return
        moveCamera(latitude, longitude)
    }

    private fun moveCamera(latitude: Double, longitude: Double) {
        val controller = mapController ?: return
        if (!controller.isRenderingActive()) return
        Framework.nativeStopLocationFollow()
        Framework.nativeZoomToPoint(latitude, longitude, zoom, false)
        controller.updateCompassOffset(0, 0)
        controller.view.postInvalidate()
        root.post { notifyCameraChanged() }
    }

    private fun notifyCameraChanged() {
        if (disposed || !renderingReady) return
        readCurrentCamera()?.let { camera ->
            channel.invokeMethod("mapCameraChanged", camera)
        }
    }

    private fun readCurrentCamera(): Map<String, Any>? = runCatching {
        val center = Framework.nativeGetScreenRectCenter()
        val latitude = center.getOrNull(0) ?: return@runCatching null
        val rawLongitude = center.getOrNull(1) ?: return@runCatching null
        val currentZoom = Framework.nativeGetDrawScale()
        if (!latitude.isFinite() ||
            !rawLongitude.isFinite() ||
            latitude !in -90.0..90.0 ||
            currentZoom < 1
        ) {
            return@runCatching null
        }
        val longitude = ((rawLongitude + 180.0) % 360.0 + 360.0) % 360.0 - 180.0
        mapOf(
            "latitude" to latitude,
            "longitude" to longitude,
            "zoom" to currentZoom.coerceIn(1, 20),
        )
    }.getOrNull()

    @SuppressLint("MissingPermission")
    private fun currentPhoneLocation(): Location? {
        engine.organicMaps.locationHelper.savedLocation?.let { return it }
        val manager = root.context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return null
        val hasFine = ContextCompat.checkSelfPermission(
            root.context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val providers = if (hasFine) {
            listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER,
            )
        } else {
            listOf(LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)
        }
        return providers.mapNotNull { provider ->
            runCatching {
                if (manager.isProviderEnabled(provider)) manager.getLastKnownLocation(provider) else null
            }.getOrNull()
        }.maxByOrNull { it.time }
    }

    private fun subscribeToMapDownloads() {
        if (!enableMapDownloads || storageCallbackSlot != null) return
        storageCallbackSlot = MapManager.nativeSubscribe(object : MapManager.StorageCallback {
            override fun onStatusChanged(data: List<MapManager.StorageCallbackData>) {
                val event = data.lastOrNull() ?: return
                root.post {
                    when (event.newStatus) {
                        CountryItem.STATUS_DONE -> {
                            pendingRegionId = null
                            channel.invokeMethod(
                                "mapDownloadFinished",
                                mapOf(
                                    "regionId" to event.countryId,
                                    "status" to "Offline map cached: ${event.countryId}",
                                ),
                            )
                            mapController?.view?.postInvalidate()
                        }
                        CountryItem.STATUS_PROGRESS,
                        CountryItem.STATUS_ENQUEUED -> channel.invokeMethod(
                            "mapDownloadProgress",
                            mapOf(
                                "regionId" to event.countryId,
                                "status" to if (event.newStatus == CountryItem.STATUS_ENQUEUED) {
                                    "Queued map: ${event.countryId}"
                                } else {
                                    "Downloading map: ${event.countryId}"
                                },
                                "progress" to null,
                            ),
                        )
                        CountryItem.STATUS_FAILED -> {
                            requestedRegions.remove(event.countryId)
                            channel.invokeMethod(
                                "mapDownloadFailed",
                                mapOf(
                                    "regionId" to event.countryId,
                                    "status" to "Map download failed: ${event.countryId}",
                                ),
                            )
                        }
                    }
                }
            }

            override fun onProgress(countryId: String, localSize: Long, remoteSize: Long) {
                val progress = if (remoteSize > 0L) {
                    (localSize.toDouble() / remoteSize.toDouble()).coerceIn(0.0, 1.0)
                } else {
                    null
                }
                root.post {
                    channel.invokeMethod(
                        "mapDownloadProgress",
                        mapOf(
                            "regionId" to countryId,
                            "status" to if (progress == null) {
                                "Downloading map: $countryId"
                            } else {
                                "Downloading map: $countryId ${(progress * 100).toInt()}%"
                            },
                            "progress" to progress,
                        ),
                    )
                }
            }
        })
    }

    private fun refreshDownloadPrompt() {
        if (!enableMapDownloads || !renderingReady) return
        val regionId = runCatching {
            if (Framework.nativeGetDrawScale() < MIN_DOWNLOAD_PROMPT_ZOOM ||
                Framework.nativeIsDownloadedMapAtScreenCenter()
            ) {
                return@runCatching null
            }
            val center = Framework.nativeGetScreenRectCenter()
            val latitude = center.getOrNull(0) ?: return@runCatching null
            val longitude = center.getOrNull(1) ?: return@runCatching null
            MapManager.nativeFindCountry(latitude, longitude)?.takeIf(String::isNotBlank)
        }.getOrNull() ?: return
        if (regionId == pendingRegionId ||
            regionId in requestedRegions ||
            regionId in dismissedRegions
        ) {
            return
        }
        pendingRegionId = regionId
        channel.invokeMethod("mapRegionAvailable", mapOf("regionId" to regionId))
    }

    private fun startRegionDownload(regionId: String) {
        pendingRegionId = null
        runCatching {
            if (ConnectionState.INSTANCE.isMobileConnected) MapManager.nativeEnableDownloadOn3g()
            if (requestedRegions.add(regionId)) MapManager.startDownload(regionId)
        }.onFailure { error ->
            requestedRegions.remove(regionId)
            channel.invokeMethod(
                "mapDownloadFailed",
                mapOf(
                    "regionId" to regionId,
                    "status" to "Map download failed: ${error.message ?: regionId}",
                ),
            )
        }
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
            markerStyle(node.marker)?.let { style ->
                append("&s=").append(Uri.encode(style))
            }
        }
    }

    private fun markerStyle(marker: String): String? = when (marker.lowercase(Locale.US)) {
        "red", "blue", "purple", "yellow", "pink", "brown", "green", "orange" ->
            "placemark-${marker.lowercase(Locale.US)}"
        "deep_purple" -> "placemark-deeppurple"
        "light_blue" -> "placemark-lightblue"
        "cyan" -> "placemark-cyan"
        "teal" -> "placemark-teal"
        "lime" -> "placemark-lime"
        "deep_orange" -> "placemark-deeporange"
        "gray", "grey" -> "placemark-gray"
        "blue_gray" -> "placemark-bluegray"
        else -> null
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

    companion object {
        private const val PHONE_LOCATION_REFRESH_MS = 1_000L
        private const val MAP_REFRESH_DELAY_MS = 250L
        private const val MIN_DOWNLOAD_PROMPT_ZOOM = 9
        private const val REGION_AUTOCACHE_INTERVAL_MS = 3_500L
        private const val REGION_AUTOCACHE_INITIAL_DELAY_MS = 5_000L
        private const val DOWNLOAD_PROMPT_GESTURE_DELAY_MS = 500L
    }
}
