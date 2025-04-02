package com.banuba.ve.sdk.flutter.plugin.ve_sdk_flutter

import android.app.Application
import android.content.Context
import android.os.Bundle
import android.util.Log
import androidx.core.net.toUri
import androidx.fragment.app.Fragment
import com.banuba.sdk.arcloud.data.source.ArEffectsRepositoryProvider
import com.banuba.sdk.arcloud.di.ArCloudKoinModule
import com.banuba.sdk.audiobrowser.data.MubertApiConfig
import com.banuba.sdk.audiobrowser.di.AudioBrowserKoinModule
import com.banuba.sdk.audiobrowser.domain.AiClippingRecommendedSoundProvider
import com.banuba.sdk.audiobrowser.domain.AudioBrowserMusicProvider
import com.banuba.sdk.audiobrowser.feedfm.AiClippingBanubaMusicTrackLoader
import com.banuba.sdk.audiobrowser.soundstripe.AiClippingSoundstripeTrackLoader
import com.banuba.sdk.audiobrowser.soundstripe.SoundstripeProvider
import com.banuba.sdk.cameraui.data.CameraConfig
import com.banuba.sdk.veui.data.EditorConfig
import com.banuba.sdk.core.data.TrackData
import com.banuba.sdk.core.data.autocut.AutoCutTrackLoader
import com.banuba.sdk.core.domain.DraftConfig
import com.banuba.sdk.core.ui.ContentFeatureProvider
import com.banuba.sdk.export.di.VeExportKoinModule
import com.banuba.sdk.gallery.di.GalleryKoinModule
import com.banuba.sdk.playback.PlayerScaleType
import com.banuba.sdk.playback.di.VePlaybackSdkKoinModule
import com.banuba.sdk.ve.data.EditorAspectSettings
import com.banuba.sdk.ve.data.aiclipping.AiClippingConfig
import com.banuba.sdk.ve.data.aspect.AspectSettings
import com.banuba.sdk.ve.data.aspect.AspectsProvider
import com.banuba.sdk.ve.di.VeSdkKoinModule
import com.banuba.sdk.ve.flow.di.VeFlowKoinModule
import com.banuba.sdk.veui.di.VeUiSdkKoinModule
import com.banuba.sdk.veui.domain.CoverProvider
import com.banuba.sdk.veui.domain.TrimmerAction
import org.json.JSONException
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin
import org.koin.core.module.Module
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.java.KoinJavaComponent.inject

class VideoEditorModule {

    internal fun initialize(application: Application, featuresConfig: FeaturesConfig) {
        startKoin {
            androidContext(application)
            allowOverride(true)

            // IMPORTANT! order of modules is required
            modules(
                VeSdkKoinModule().module,
                VeExportKoinModule().module,
                VePlaybackSdkKoinModule().module,

                AudioBrowserKoinModule().module,

                // IMPORTANT! ArCloudKoinModule should be set before TokenStorageKoinModule to get effects from the cloud
                ArCloudKoinModule().module,

                VeUiSdkKoinModule().module,
                VeFlowKoinModule().module,
                GalleryKoinModule().module,
                // Sample integration module
                SampleIntegrationVeKoinModule(featuresConfig).module,

                )
        }
    }
}

/**
 * All dependencies mentioned in this module will override default
 * implementations provided in VE UI SDK.
 * Some dependencies has no default implementations. It means that
 * these classes fully depends on your requirements
 */
private class SampleIntegrationVeKoinModule(featuresConfig: FeaturesConfig) {

    val module = module {
        single<ArEffectsRepositoryProvider>(createdAtStart = true) {
            ArEffectsRepositoryProvider(
                arEffectsRepository = get(named("backendArEffectsRepository")),
                ioDispatcher = get(named("ioDispatcher"))
            )
        }
        single(named("exportDir")) {
            get<Context>().getExternalFilesDir("")?.toUri()
                ?.buildUpon()
                ?.appendPath("export")
                ?.build()
                ?: throw NullPointerException("exportDir cannot be null!")
        }
        Log.d(
            TAG_FEATURES_CONFIG,
            "Add $INPUT_PARAM_FEATURES_CONFIG with params: $featuresConfig"
        )
        this.applyFeaturesConfig(featuresConfig)
    }

    private fun Module.applyFeaturesConfig(featuresConfig: FeaturesConfig) {
        this.single<ContentFeatureProvider<TrackData, Fragment>>(
            named("musicTrackProvider")
        ) {
            when (featuresConfig.audioBrowser.source) {
                FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_SOUNDSTRIPE -> SoundstripeProvider()
                else -> {
                    AudioBrowserMusicProvider()
                }
            }
        }

        if (featuresConfig.audioBrowser.source == FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_MUBERT) {
            this.addMubertParams(featuresConfig)
        }

        featuresConfig.aiClipping?.let { params ->
            factory {
                AiClippingConfig(
                    audioDataUrl = params.audioDataUrl,
                    audioTracksUrl = params.audioTracksUrl
                )
            }

            factory<ContentFeatureProvider<TrackData, Fragment>>(
                named("recommendedSoundsMusicTrackProvider")
            ) {
                AiClippingRecommendedSoundProvider()
            }

            this.single<AutoCutTrackLoader> {
                when (featuresConfig.audioBrowser.source) {
                    FEATURES_CONFIG_AUDIO_BROWSER_SOURCE_BANUBA_MUSIC -> {
                        AiClippingBanubaMusicTrackLoader(
                            contentProvider = get()
                        )
                    }

                    else -> {
                        AiClippingSoundstripeTrackLoader(
                            soundstripeApi = get()
                        )
                    }
                }
            }
        }

        single<EditorConfig> {
            EditorConfig(
                maxTotalVideoDurationMs = featuresConfig.durationConfig.maximumVideoDuration,
//                trimmerMinSourceVideoDurationMs = 3000,
                slideShowSourceVideoDurationMs = 4000,
                minTotalVideoDurationMs = 4000
            )
        }


//        this.single<ExportSessionHelper> {
//            FlowExportSessionHelper(
//                draftManager = get()
//            )
//        }

        single {
            CameraConfig(
                maxRecordedTotalVideoDurationMs = featuresConfig.durationConfig.maximumVideoDuration,
                videoDurations = featuresConfig.durationConfig.videoDurations,
                minRecordedTotalVideoDurationMs = 4000,

                )

        }

        if (!featuresConfig.editorConfig.enableVideoAspectFill) {
            factory<PlayerScaleType>(named("editorVideoScaleType")) {
                PlayerScaleType.CENTER_INSIDE
            }
        }

        single<AspectsProvider> {
            object : AspectsProvider {
                override var availableAspects: List<AspectSettings> = listOf()
                override fun provide(): AspectsProvider.AspectsData {
                    return AspectsProvider.AspectsData(
                        allAspects = availableAspects,
                        default = EditorAspectSettings.Original()
                    )
                }

                override fun setBundle(bundle: Bundle) {

                }
            }
        }

        if (!featuresConfig.editorConfig.enableVideoCover) {
            single<CoverProvider> {
                CoverProvider.NONE
            }
        }


        factory<DraftConfig> {
            when (featuresConfig.draftConfig.option) {
                FEATURES_CONFIG_DRAFT_CONFIG_AUTO ->
                    DraftConfig.ENABLED_SAVE_BY_DEFAULT

                FEATURES_CONFIG_DRAFT_CONFIG_CLOSE_ON_SAVE ->
                    DraftConfig.ENABLED_ASK_IF_SAVE_NOT_EXPORT

                FEATURES_CONFIG_DRAFT_CONFIG_DISABLED ->
                    DraftConfig.DISABLED

                else -> {
                    DraftConfig.ENABLED_ASK_TO_SAVE
                }
            }
        }
    }

    private fun Module.addMubertParams(featuresConfig: FeaturesConfig) {
        val paramsObject = featuresConfig.audioBrowser.params

        if (paramsObject != null) {
            try {
                val paramsMap = paramsObject.keys().asSequence().associateWith { key ->
                    paramsObject.get(key)
                }

                val mubertLicence =
                    paramsMap[FEATURES_CONFIG_AUDIO_BROWSER_PARAMS_MUBERT_LICENCE] as? String
                val mubertToken =
                    paramsMap[FEATURES_CONFIG_AUDIO_BROWSER_PARAMS_MUBERT_TOKEN] as? String

                if (mubertLicence != null && mubertToken != null) {
                    this.single {
                        MubertApiConfig(
                            mubertLicence = mubertLicence,
                            mubertToken = mubertToken
                        )
                    }
                } else {
                    Log.w(TAG, "Missing parameters mubertLicence and mubertToken")
                    return
                }
            } catch (e: JSONException) {
                Log.w(TAG, "Error parsing Params of AudioBrowser")
                return
            }
        } else {
            Log.w(TAG, "Missing Params in AudioBrowser")
            return
        }
    }
}
