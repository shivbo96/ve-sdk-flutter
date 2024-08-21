package com.banuba.ve.sdk.flutter.plugin.ve_sdk_flutter

import android.util.Log
import org.json.JSONException
import org.json.JSONObject

internal fun parseFeaturesConfig(rawConfigParams: String?): FeaturesConfig =
    if (rawConfigParams.isNullOrEmpty()) {
        emptyFeaturesConfig
    } else {
        try {
            val featuresConfigObject = JSONObject(rawConfigParams)
            FeaturesConfig(
                featuresConfigObject.extractAiClipping(),
                featuresConfigObject.extractAiCaptions(),
                featuresConfigObject.extractAudioBrowser(),
                featuresConfigObject.extractEditorConfig(),
                featuresConfigObject.extractCameraConfig(),
                featuresConfigObject.extractDraftConfig()
            )
        } catch (e: JSONException) {
            emptyFeaturesConfig
        }
    }

private fun JSONObject.extractAiClipping(): AiClipping? {
    return try {
        this.optJSONObject(FEATURES_CONFIG_AI_CLIPPING)?.let { json ->
            AiClipping(
                audioDataUrl = json.optString(FEATURES_CONFIG_AI_CLIPPING_AUDIO_DATA_URL),
                audioTracksUrl = json.optString(FEATURES_CONFIG_AI_CLIPPING_AUDIO_TRACK_URL)
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing AiClipping params", e)
        null
    }
}

private fun JSONObject.extractAiCaptions(): AiCaptions? {
    return try {
        this.optJSONObject(FEATURES_CONFIG_AI_CAPTIONS)?.let { json ->
            AiCaptions(
                uploadUrl = json.optString(FEATURES_CONFIG_AI_CAPTIONS_UPLOAD_URL),
                transcribeUrl = json.optString(FEATURES_CONFIG_AI_CAPTIONS_TRANSCRIBE_URL),
                apiKey = json.optString(FEATURES_CONFIG_AI_CAPTIONS_API_KEY)
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing AiCaptions params", e)
        null
    }
}

private fun JSONObject.extractAudioBrowser(): AudioBrowser =
    try {
        this.optJSONObject(FEATURES_CONFIG_AUDIO_BROWSER)?.let { json ->
            AudioBrowser(
                source = json.optString(FEATURES_CONFIG_AUDIO_BROWSER_SOURCE),
                params = json.optJSONObject(FEATURES_CONFIG_AUDIO_BROWSER_PARAMS)
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing Audio Browser params", e)
        defaultAudioBrowser
    } ?: defaultAudioBrowser

private fun JSONObject.extractEditorConfig(): EditorConfig =
    try {
        this.optJSONObject(FEATURES_CONFIG_EDITOR_CONFIG)?.let { json ->
            EditorConfig(
                enableVideoAspectFill = json.optBoolean(
                    FEATURES_CONFIG_EDITOR_CONFIG_ENABLE_VIDEO_ASPECT_FILL
                ),
                enableVideoCover = json.optBoolean(
                    FEATURES_CONFIG_EDITOR_CONFIG_ENABLE_VIDEO_COVER
                )
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing Editor Config params", e)
        defaultEditorConfig
    } ?: defaultEditorConfig

private fun JSONObject.extractCameraConfig(): CameraConfig =
    try {
        this.optJSONObject(FEATURES_CONFIG_DURATION_CONFIG)?.let { json ->

            // Extract maximum video duration as a Long
            val maximumVideoDuration = json.optLong(FEATURES_CONFIG_DURATION_CONFIG_MAXIMUM_VIDEO_DURATION)

            // Extract video durations as a JSONArray and convert to List<Long>
            val videoDurationsJsonArray = json.optJSONArray(FEATURES_CONFIG_DURATION_CONFIG_VIDEO_DURATIONS)
            val videoDurations = mutableListOf<Long>()

            if (videoDurationsJsonArray != null) {
                for (i in 0 until videoDurationsJsonArray.length()) {
                    videoDurations.add(videoDurationsJsonArray.getLong(i))
                }
            }

            CameraConfig(
                maximumVideoDuration = maximumVideoDuration,
                videoDurations = videoDurations
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing Editor Duration params", e)
        defaultDurationConfig
    } ?: defaultDurationConfig


private fun JSONObject.extractDraftConfig(): DraftConfig =
    try {
        this.optJSONObject(FEATURES_CONFIG_DRAFT_CONFIG)?.let { json ->
            DraftConfig(
                option = json.optString(FEATURES_CONFIG_DRAFT_CONFIG_OPTION)
            )
        }
    } catch (e: JSONException) {
        Log.d(TAG, "Missing Draft Config params", e)
        defaultDraftConfig
    } ?: defaultDraftConfig