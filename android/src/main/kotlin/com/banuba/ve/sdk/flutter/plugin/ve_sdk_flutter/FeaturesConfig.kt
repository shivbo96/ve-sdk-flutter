package com.banuba.ve.sdk.flutter.plugin.ve_sdk_flutter

import org.json.JSONObject

internal data class FeaturesConfig(
    val aiClipping: AiClipping? = null,
    val aiCaptions: AiCaptions? = null,
    val audioBrowser: AudioBrowser = defaultAudioBrowser,
    val editorConfig: EditorConfig = defaultEditorConfig,
    val draftConfig: DraftConfig = defaultDraftConfig
)

internal data class AiClipping(
    val audioDataUrl: String,
    val audioTracksUrl: String
)

internal data class AiCaptions(
    val uploadUrl: String,
    val transcribeUrl: String,
    val apiKey: String
)

internal data class AudioBrowser(
    val source: String,
    val params: JSONObject?
)

internal val defaultAudioBrowser = AudioBrowser(
    source = FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_LOCAL,
    params = null
)

internal data class EditorConfig(
    val enableVideoAspectFill: Boolean
)

internal val defaultEditorConfig = EditorConfig(
    enableVideoAspectFill = true
)

internal data class DraftConfig(
    val option: String
)

internal val defaultDraftConfig = DraftConfig(
    option = "askToSave"
)