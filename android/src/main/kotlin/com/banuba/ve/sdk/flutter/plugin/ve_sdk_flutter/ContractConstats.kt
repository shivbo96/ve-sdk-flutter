package com.banuba.ve.sdk.flutter.plugin.ve_sdk_flutter

import androidx.core.os.bundleOf
import android.os.Bundle
import com.banuba.sdk.veui.data.captions.CaptionsApiService
import android.util.Log

// Tag
internal const val TAG = "VideoEditorPlugin"

internal const val TAG_FEATURES_CONFIG = "FeaturesConfig"

// Method channel
internal const val CHANNEL = "ve_sdk_flutter"
internal const val METHOD_START = "startVideoEditor"

// Input params
internal const val INPUT_PARAM_TOKEN = "token"
internal const val INPUT_PARAM_FEATURES_CONFIG = "featuresConfig"
internal const val INPUT_PARAM_SCREEN = "screen"
internal const val INPUT_PARAM_VIDEO_SOURCES = "videoSources"
internal const val INPUT_PARAM_DRAFT_VIDEO_SEQUENCE = "draftSequenceId"


// Exported params
internal const val EXPORTED_VIDEO_SOURCES = "exportedVideoSources"
internal const val EXPORTED_PREVIEW = "exportedPreview"
internal const val EXPORTED_META = "exportedMeta"
internal const val EXPORTED_MUSTIC_TRACK = "musicFileName"
internal const val DRAFT_INDEX = "draftIndex"
internal const val DRAFT_VIDEO_SEQUENCE = "draftVideoSequence"

// Features config params
internal const val FEATURES_CONFIG_AI_CAPTIONS = "aiCaptions"
internal const val FEATURES_CONFIG_AI_CAPTIONS_UPLOAD_URL = "uploadUrl"
internal const val FEATURES_CONFIG_AI_CAPTIONS_TRANSCRIBE_URL = "transcribeUrl"
internal const val FEATURES_CONFIG_AI_CAPTIONS_API_KEY = "apiKey"

internal const val FEATURES_CONFIG_AI_CLIPPING = "aiClipping"
internal const val FEATURES_CONFIG_AI_CLIPPING_AUDIO_DATA_URL = "audioDataUrl"
internal const val FEATURES_CONFIG_AI_CLIPPING_AUDIO_TRACK_URL = "audioTracksUrl"

internal const val FEATURES_CONFIG_AUDIO_BROWSER = "audioBrowser"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_SOURCE = "source"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_PARAMS = "params"

internal const val FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_LOCAL = "local"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_MUBERT = "mubert"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_SOUNDSTRIPE = "soundstripe"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_BANUBA_MUSIC = "banubaMusic"

internal const val FEATURES_CONFIG_AUDIO_BROWSER_PARAMS_MUBERT_LICENCE = "mubertLicence"
internal const val FEATURES_CONFIG_AUDIO_BROWSER_PARAMS_MUBERT_TOKEN = "mubertToken"

internal const val FEATURES_CONFIG_EDITOR_CONFIG = "editorConfig"
internal const val FEATURES_CONFIG_EDITOR_CONFIG_ENABLE_VIDEO_ASPECT_FILL = "enableVideoAspectFill"
internal const val FEATURES_CONFIG_EDITOR_CONFIG_ENABLE_VIDEO_COVER = "enableVideoCover"

internal const val FEATURES_CONFIG_DURATION_CONFIG_MAXIMUM_VIDEO_DURATION = "maximumVideoDuration"
internal const val FEATURES_CONFIG_DURATION_CONFIG_VIDEO_DURATIONS = "videoDurations"

internal const val FEATURES_CONFIG_DRAFT_CONFIG = "draftConfig"
internal const val FEATURES_CONFIG_DURATION_CONFIG = "durationConfig"
internal const val FEATURES_CONFIG_DRAFT_CONFIG_OPTION = "option"
internal const val FEATURES_CONFIG_DRAFT_CONFIG_DURATION = "duration"

internal const val FEATURES_CONFIG_DRAFT_CONFIG_ASK_TO_SAVE = "askToSave"
internal const val FEATURES_CONFIG_DRAFT_CONFIG_CLOSE_ON_SAVE = "closeOnSave"
internal const val FEATURES_CONFIG_DRAFT_CONFIG_AUTO = "auto"
internal const val FEATURES_CONFIG_DRAFT_CONFIG_DISABLED = "disabled"

// Screens
internal const val SCREEN_CAMERA = "camera"
internal const val SCREEN_PIP = "pip"
internal const val SCREEN_TRIMMER = "trimmer"
internal const val SCREEN_GET_ALL_DRAFT = "getAllDraft"
internal const val SCREEN_REMOVE_DRAFT = "removeDraft"
internal const val SCREEN_EDITOR = "editor"

// Errors
internal const val ERR_CODE_SDK_NOT_INITIALIZED = "ERR_SDK_NOT_INITIALIZED"
internal const val ERR_CODE_SDK_LICENSE_REVOKED = "ERR_SDK_LICENSE_REVOKED"
internal const val ERR_MISSING_HOST = "ERR_MISSING_HOST"
internal const val ERR_INVALID_PARAMS = "ERR_INVALID_PARAMS"
internal const val ERR_MISSING_EXPORT_RESULT = "ERR_MISSING_EXPORT_RESULT"

internal const val ERR_MESSAGE_SDK_NOT_INITIALIZED = """
    Failed to initialize SDK!!! 
    The license token is incorrect: empty or truncated.
    Please check the license token and try again.
"""
internal const val ERR_MESSAGE_LICENSE_REVOKED = """
    "WARNING!!!
    YOUR LICENSE TOKEN EITHER EXPIRED OR REVOKED!
    Please contact Banuba"
"""

internal const val ERR_MESSAGE_MISSING_TOKEN =
    "Missing license token: set correct value to $INPUT_PARAM_TOKEN input params"

internal const val ERR_MESSAGE_MISSING_SCREEN =
    "Missing screen: set correct value to $INPUT_PARAM_SCREEN input params"

internal const val ERR_MESSAGE_MISSING_PIP_VIDEO =
    "Missing pip video source: set correct value to $INPUT_PARAM_VIDEO_SOURCES input params"

internal const val ERR_MESSAGE_MISSING_TRIMMER_VIDEO_SOURCES =
    "Missing trimmer video sources: set correct value to $INPUT_PARAM_VIDEO_SOURCES input params"

internal const val ERR_MESSAGE_UNKNOWN_SCREEN =
    "Invalid $INPUT_PARAM_SCREEN value: available values($SCREEN_CAMERA, $SCREEN_PIP, $SCREEN_TRIMMER)"

internal const val ERR_MESSAGE_MISSING_EXPORT_RESULT =
    "Missing export result: video export has not been completed successfully. Please try again"

internal const val ERR_MESSAGE_MISSING_HOST = "Missing host Activity to start video editor"

internal const val ERR_MESSAGE_INVALID_CONFIG =
    "Missing or invalid config params, will use default config. Input params: $INPUT_PARAM_FEATURES_CONFIG"

//Prepare Extras from AiCaptions
internal fun prepareExtras(featuresConfig: FeaturesConfig): Bundle {
    val bundle = Bundle()
    featuresConfig.aiCaptions?.let { params ->
        bundle.putString(CaptionsApiService.ARG_CAPTIONS_UPLOAD_URL, params.uploadUrl)
        bundle.putString(CaptionsApiService.ARG_CAPTIONS_TRANSCRIBE_URL, params.transcribeUrl)
        bundle.putString(CaptionsApiService.ARG_API_KEY, params.apiKey)
    }
    return bundle
}

//Empty Feature Config
internal val emptyFeaturesConfig = FeaturesConfig()