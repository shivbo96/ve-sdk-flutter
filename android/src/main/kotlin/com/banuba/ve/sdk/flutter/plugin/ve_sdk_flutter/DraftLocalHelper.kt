package com.banuba.ve.sdk.flutter.plugin.ve_sdk_flutter

import android.net.Uri
import com.banuba.sdk.core.Rotation
import com.banuba.sdk.core.data.Draft
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object DraftLocalHelper {
    // Function to parse session.json file
    fun parseSessionJson(filePath: String): List<Draft> {
        val file = File(filePath)
        if (!file.exists()) return emptyList()

        val jsonData = file.readText()
        val jsonObject = JSONObject(jsonData)
        val availableSessions = jsonObject.getJSONArray("available")

        val sessions = mutableListOf<Draft>()
        for (i in 0 until availableSessions.length()) {
            val obj = availableSessions.getJSONObject(i)
            val preview = obj.getString("preview")
            if (!preview.isNullOrEmpty()) {
                sessions.add(
                    Draft(
                        sameDayIndex = obj.getInt("sameDayIndex"),
                        creationTimestampMs = obj.getLong("created_at"),
                        preview = Draft.Preview(
                            uri = Uri.parse(obj.getString("preview")),
                            rotation = Rotation.valueOf(obj.getString("preview_rotation"))
                        ),
                        dir = File(obj.getString("dir")),
                        durationMs = obj.getLong("duration")
                    )
                )
            }
        }
        return sessions
    }

    // Function to get latest session's createdAt
    fun getLatestSessionInfo(filePath: String): Long? {
        val sessions = parseSessionJson(filePath).sortedByDescending { it.creationTimestampMs }
        return sessions.firstOrNull()?.creationTimestampMs
    }

    // Function to get full session object by createdAt
    fun getSessionByCreatedDate(filePath: String, createdAt: Long): Draft? {
        return parseSessionJson(filePath).find { it.creationTimestampMs == createdAt }

    }

    fun getSessionBySameDayIndex(filePath: String, index: Int): Draft? {
        return parseSessionJson(filePath).find { it.sameDayIndex == index }

    }

    // Function to delete a session by createdAt
    fun deleteSessionByCreatedDate(filePath: String, createdAt: Long): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        val jsonData = file.readText()
        val jsonObject = JSONObject(jsonData)
        val availableSessions = jsonObject.getJSONArray("available")

        val updatedSessions = JSONArray()
        for (i in 0 until availableSessions.length()) {
            val obj = availableSessions.getJSONObject(i)
            if (obj.getLong("created_at") != createdAt) {
                updatedSessions.put(obj)
            }
        }
        jsonObject.put("available", updatedSessions)
        file.writeText(jsonObject.toString(4))
        return true
    }
}