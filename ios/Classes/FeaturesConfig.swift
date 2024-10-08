import Foundation

struct FeaturesConfig: Codable {
    let aiCaptions: AiCaptions?
    let aiClipping: AiClipping?
    let audioBrowser: AudioBrowser
    let editorConfig: EditorConfig
    let draftConfig: DraftConfig
    let durationConfig: DurationConfig
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

struct DurationConfig: Codable {
    let maximumVideoDuration: Double
    let videoDurations:Array<Double>
}

struct DraftConfig: Codable {
    let option: String
}

