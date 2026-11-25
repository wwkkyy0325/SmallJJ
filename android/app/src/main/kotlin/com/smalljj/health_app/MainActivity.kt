package com.smalljj.health_app

import android.content.Intent
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * 小布 / 桌面快捷方式 / adb 的统一入口。
 *
 * 支持的链接见 lib/platform/app_intents.dart 顶部注释。
 * 只用端侧 Intent，不依赖 OPPO 平台的 client_id，也不需要联网。
 */
class MainActivity : FlutterActivity() {
    private var pendingIntentUri: String? = null
    private var channel: MethodChannel? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingIntentUri = intent?.dataString
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smalljj/intent")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialIntent" -> {
                    result.success(pendingIntentUri)
                    // 冷启动的链接只消费一次
                    pendingIntentUri = null
                }
                "speak" -> {
                    (call.arguments as? String)?.let { speak(it) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 数据库目录：只给出应用私有 files 目录，不引入 path_provider。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smalljj/paths")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "filesDir" -> result.success(filesDir.absolutePath)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uri = intent.dataString ?: return
        if (channel != null) {
            channel?.invokeMethod("open", uri)
        } else {
            pendingIntentUri = uri
        }
    }

    /** 系统 TTS 播报；没装中文语音包就静默跳过，绝不阻断落库。 */
    private fun speak(text: String) {
        if (tts == null) {
            tts = TextToSpeech(applicationContext) { status ->
                ttsReady = status == TextToSpeech.SUCCESS
                if (ttsReady) {
                    tts?.language = Locale.CHINA
                }
            }
            // 首帧引擎还没就绪，稍等再说一次
            handler.postDelayed({ if (ttsReady) tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "smalljj") }, 600)
            return
        }
        if (ttsReady) {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "smalljj")
        }
    }

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onDestroy() {
        tts?.shutdown()
        tts = null
        ttsReady = false
        super.onDestroy()
    }
}
