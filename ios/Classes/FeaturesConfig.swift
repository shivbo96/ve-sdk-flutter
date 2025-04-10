import Foundation
import BanubaVideoEditorSDK
import BanubaAudioBrowserSDK

struct FeaturesConfig: Codable {
    let aiCaptions: AiCaptions?
    let aiClipping: AiClipping?
    let audioBrowser: AudioBrowser
    let editorConfig: EditorConfig
    let draftsConfig: DraftsConfig
    let gifPickerConfig: GifPickerConfig?
    let videoDurationConfig: VideoDurationConfig
    let enableEditorV2: Bool
    let processPictureExternally: Bool
}

struct AiClipping: Codable {
    let audioDataUrl: String
    let audioTracksUrl: String
}

struct AiCaptions: Codable {
    let uploadUrl: String
    let transcribeUrl: String
    let apiKey: String
}

struct AudioBrowser: Codable {
    let source: String
    let params: Params?
    
    public func value() -> AudioBrowserMusicSource{
        switch source {
            case VideoEditorConfig.featuresConfigAudioBrowserSourceSoundstripe:
                return .soundstripe
            case VideoEditorConfig.featuresConfigAudioBrowserSourceLocal:
                return .localStorageWithMyFiles
            case VideoEditorConfig.featuresConfigAudioBrowserSourceBanubaMusic:
                return .banubaMusic
            default:
                return .allSources
        }
    }
}

struct Params: Codable {
    let mubertLicence: String?
    let mubertToken: String?
}

struct EditorConfig: Codable {
    let enableVideoAspectFill: Bool
    let enableVideoCover: Bool
    let saveButtonText: String
}

struct DraftsConfig: Codable {
    let option: String

    public func value() -> DraftsFeatureConfig {
        switch option {
            case VideoEditorConfig.featuresConfigDraftConfigOptionAuto:
                return .enabledSaveToDraftsByDefault
            case VideoEditorConfig.featuresConfigDraftConfigOptionСloseOnSave:
                return .enabledAskIfSaveNotExport
            case VideoEditorConfig.featuresConfigDraftConfigOptionDisabled:
                return .disabled
            default:
                return .enabled
        }
    }
}

struct GifPickerConfig: Codable {
    let giphyApiKey: String
}

struct VideoDurationConfig: Codable {
    let maxTotalVideoDuration: TimeInterval
    let videoDurations: [TimeInterval]

    public func value() -> VideoEditorDurationConfig {
        return VideoEditorDurationConfig(
            maximumVideoDuration: maxTotalVideoDuration,
            videoDurations: videoDurations,
            minimumDurationFromCamera: 4.0,
            minimumDurationFromGallery: 0.4,
            minimumVideoDuration: 4.0,
            minimumTrimmedPartDuration: 0.4,
            slideshowDuration: 4.0
        )
    }
}
