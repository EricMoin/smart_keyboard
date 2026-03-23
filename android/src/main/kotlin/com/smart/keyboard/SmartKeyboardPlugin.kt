package com.smart.keyboard

import android.app.Activity
import android.content.Context
import android.graphics.Rect
import android.os.Build
import android.view.View
import android.view.ViewTreeObserver
import android.view.inputmethod.InputMethodManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmartKeyboardPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL_NAME = "com.smart.keyboard/method"
        private const val EVENT_CHANNEL_NAME = "com.smart.keyboard/event"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var contentView: View? = null

    private var currentKeyboardHeightPx: Int = 0
    private var targetKeyboardHeightPx: Int = 0

    private var insetsAnimationCallback: WindowInsetsAnimationCompat.Callback? = null
    private var globalLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachKeyboardListeners()

        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)

        methodChannel = null
        eventChannel = null
        eventSink = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getKeyboardHeight" -> {
                val keyboardHeightPx = resolveKeyboardHeightPx()
                result.success(toLogicalPixels(keyboardHeightPx))
            }

            "showKeyboard" -> {
                showKeyboard()
                result.success(null)
            }

            "hideKeyboard" -> {
                hideKeyboard()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        emitKeyboardEvent(resolveKeyboardHeightPx(), isAnimating = false)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        attachKeyboardListeners()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachKeyboardListeners()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        attachKeyboardListeners()
    }

    override fun onDetachedFromActivity() {
        detachKeyboardListeners()
        activity = null
    }

    private fun attachKeyboardListeners() {
        val activeActivity = activity ?: return
        val view = activeActivity.window.decorView.findViewById<View>(android.R.id.content) ?: return

        detachKeyboardListeners()
        contentView = view

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            attachModernInsetsListeners(view)
        } else {
            attachLegacyGlobalLayoutListener(view)
        }

        view.requestApplyInsets()
    }

    private fun detachKeyboardListeners() {
        val view = contentView

        if (view != null) {
            globalLayoutListener?.let { listener ->
                if (view.viewTreeObserver.isAlive) {
                    view.viewTreeObserver.removeOnGlobalLayoutListener(listener)
                }
            }

            ViewCompat.setWindowInsetsAnimationCallback(view, null)
        }

        globalLayoutListener = null
        insetsAnimationCallback = null
        contentView = null
        currentKeyboardHeightPx = 0
        targetKeyboardHeightPx = 0
    }

    private fun attachModernInsetsListeners(view: View) {
        insetsAnimationCallback = object :
            WindowInsetsAnimationCompat.Callback(DISPATCH_MODE_STOP) {

            override fun onStart(
                animation: WindowInsetsAnimationCompat,
                bounds: WindowInsetsAnimationCompat.BoundsCompat,
            ): WindowInsetsAnimationCompat.BoundsCompat {
                if ((animation.typeMask and WindowInsetsCompat.Type.ime()) != 0) {
                    val imeVisible = ViewCompat.getRootWindowInsets(view)
                        ?.isVisible(WindowInsetsCompat.Type.ime()) ?: false
                    targetKeyboardHeightPx = if (imeVisible) {
                        bounds.upperBound.bottom
                    } else {
                        0
                    }
                }
                return bounds
            }

            override fun onProgress(
                insets: WindowInsetsCompat,
                runningAnimations: MutableList<WindowInsetsAnimationCompat>,
            ): WindowInsetsCompat {
                val hasImeAnimation = runningAnimations.any {
                    (it.typeMask and WindowInsetsCompat.Type.ime()) != 0
                }
                if (hasImeAnimation) {
                    val keyboardHeightPx = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
                    emitKeyboardEvent(keyboardHeightPx, isAnimating = true)
                }
                return insets
            }

            override fun onEnd(animation: WindowInsetsAnimationCompat) {
                if ((animation.typeMask and WindowInsetsCompat.Type.ime()) != 0) {
                    val keyboardHeightPx = ViewCompat.getRootWindowInsets(view)
                        ?.getInsets(WindowInsetsCompat.Type.ime())
                        ?.bottom
                        ?: 0
                    emitKeyboardEvent(keyboardHeightPx, isAnimating = false)
                }
            }
        }
        ViewCompat.setWindowInsetsAnimationCallback(view, insetsAnimationCallback)
    }

    private fun attachLegacyGlobalLayoutListener(view: View) {
        globalLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
            val keyboardHeightPx = calculateLegacyKeyboardHeightPx(view)
            if (keyboardHeightPx != currentKeyboardHeightPx) {
                targetKeyboardHeightPx = keyboardHeightPx
                emitKeyboardEvent(keyboardHeightPx, isAnimating = false)
            }
        }

        view.viewTreeObserver.addOnGlobalLayoutListener(globalLayoutListener)
    }

    private fun calculateLegacyKeyboardHeightPx(view: View): Int {
        val visibleRect = Rect()
        view.getWindowVisibleDisplayFrame(visibleRect)
        val screenHeightPx = view.rootView.height
        return (screenHeightPx - visibleRect.bottom).coerceAtLeast(0)
    }

    private fun resolveKeyboardHeightPx(): Int {
        val view = contentView ?: activity?.window?.decorView?.findViewById(android.R.id.content)
        if (view != null) {
            val rootInsets = ViewCompat.getRootWindowInsets(view)
            if (rootInsets != null) {
                return rootInsets.getInsets(WindowInsetsCompat.Type.ime()).bottom
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                return calculateLegacyKeyboardHeightPx(view)
            }
        }

        return currentKeyboardHeightPx
    }

    private fun showKeyboard() {
        val activeActivity = activity ?: return
        val view = contentView ?: activeActivity.window.decorView.findViewById(android.R.id.content)
        val targetView = activeActivity.currentFocus ?: view

        if (targetView != null) {
            targetView.requestFocus()
        }

        val controller = view?.let { ViewCompat.getWindowInsetsController(it) }
        if (controller != null) {
            controller.show(WindowInsetsCompat.Type.ime())
            return
        }

        val imm = activeActivity.getSystemService(Context.INPUT_METHOD_SERVICE)
        if (imm is InputMethodManager) {
            imm.showSoftInput(targetView ?: activeActivity.window.decorView, InputMethodManager.SHOW_IMPLICIT)
        }
    }

    private fun hideKeyboard() {
        val activeActivity = activity ?: return
        val view = contentView ?: activeActivity.window.decorView.findViewById(android.R.id.content)
        val controller = view?.let { ViewCompat.getWindowInsetsController(it) }

        if (controller != null) {
            controller.hide(WindowInsetsCompat.Type.ime())
            return
        }

        val token = (activeActivity.currentFocus ?: view ?: activeActivity.window.decorView).windowToken
        val imm = activeActivity.getSystemService(Context.INPUT_METHOD_SERVICE)
        if (imm is InputMethodManager) {
            imm.hideSoftInputFromWindow(token, 0)
        }
    }

    private fun emitKeyboardEvent(heightPx: Int, isAnimating: Boolean) {
        currentKeyboardHeightPx = heightPx.coerceAtLeast(0)
        val mapData = mapOf(
            "height" to toLogicalPixels(currentKeyboardHeightPx),
            "targetHeight" to toLogicalPixels(targetKeyboardHeightPx.coerceAtLeast(0)),
            "isAnimating" to isAnimating,
            "isVisible" to (currentKeyboardHeightPx > 0),
        )
        eventSink?.success(mapData)
    }

    private fun toLogicalPixels(physicalPixels: Int): Double {
        return physicalPixels / resolveDensity().toDouble()
    }

    private fun resolveDensity(): Float {
        val densityFromActivity = activity?.resources?.displayMetrics?.density
        if (densityFromActivity != null && densityFromActivity > 0f) {
            return densityFromActivity
        }

        val densityFromContext = applicationContext?.resources?.displayMetrics?.density
        if (densityFromContext != null && densityFromContext > 0f) {
            return densityFromContext
        }

        return 1f
    }
}
