package com.smalljj.health_app

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import java.util.Calendar

/**
 * 通知栏磁贴：下拉状态栏点一下，直接进「记体重」，时段按钟点猜好。
 *
 * 为什么要有它：小布没有「打开第三方 scheme」这个动作（见 docs/手机助手接入.md），
 * 语音那条路走不通，就得给一条不依赖任何助手的一步入口。
 * 落点和 adb / 桌面快捷方式完全同一条：smalljj://weight?slot=...
 */
class WeightTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = getString(R.string.tile_weight)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                subtitle = slotLabel()
            }
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val target = Intent(Intent.ACTION_VIEW, Uri.parse("smalljj://weight?slot=${slotKey()}"))
            .setClass(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14 起只收 PendingIntent
            val pending = PendingIntent.getActivity(
                this,
                0,
                target,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(target)
        }
    }

    /** 和 Dart 侧的 guessSlotLabel 用同一套阈值：11 点前早上，17 点后晚上，其余任意。 */
    private fun slotKey(): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return when {
            hour < 11 -> "morning"
            hour >= 17 -> "evening"
            else -> "other"
        }
    }

    private fun slotLabel(): String = when (slotKey()) {
        "morning" -> getString(R.string.tile_weight_morning)
        "evening" -> getString(R.string.tile_weight_evening)
        else -> getString(R.string.tile_weight_any)
    }
}
