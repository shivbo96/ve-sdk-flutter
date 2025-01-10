//
//  VideoEditorModule.swift
//  ve_sdk_flutter
//
//  Created by Gleb Prischepa on 5/4/24.
//

import Foundation
import BanubaVideoEditorSDK
import BanubaAudioBrowserSDK
import VideoEditor
import VEExportSDK
import Flutter

protocol VideoEditor {
    func initVideoEditor(token: String, featuresConfig: FeaturesConfig) -> Bool
    
    func openVideoEditorDefault(fromViewController controller: FlutterViewController, flutterResult: @escaping FlutterResult)
    
    func openVideoEditorPIP(fromViewController controller: FlutterViewController, videoURL: URL, flutterResult: @escaping FlutterResult)
    
    func openVideoEditorTrimmer(fromViewController controller: FlutterViewController, videoSources: Array<URL>, flutterResult: @escaping FlutterResult)
    
    func getAllDraftsList(flutterResult: @escaping FlutterResult)
    
    func removeDraftFromList(draftpath:String,flutterResult: @escaping FlutterResult)
    
    func openEditor(draftpath:String,fromViewController controller: FlutterViewController, flutterResult: @escaping FlutterResult)

}

class VideoEditorModule: VideoEditor {
    
    private var videoEditorSDK: BanubaVideoEditor?
    private var flutterResult: FlutterResult?

    // Use “true” if you want users could restore the last video editing session.
    private let restoreLastVideoEditingSession: Bool = false

    func initVideoEditor(token: String, featuresConfig: FeaturesConfig) -> Bool {
        guard videoEditorSDK == nil else {
            debugPrint("Video Editor SDK is already initialized")
            return true
        }
        
        var config = VideoEditorConfig()
    
        config.videoDurationConfiguration.maximumVideoDuration = featuresConfig.durationConfig.maximumVideoDuration
        
        config.videoDurationConfiguration.videoDurations = featuresConfig.durationConfig.videoDurations
        config.featureConfiguration.isVideoCoverSelectionEnabled = featuresConfig.editorConfig.enableVideoCover
        config.featureConfiguration.isAspectsEnabled = false
        config.featureConfiguration.draftsConfig = .enabledSaveToDraftsByDefault
        
        config.recorderConfiguration.previewScalingMode = .aspectFit


        config.draftsConfiguration.backButton.menuActions = [PopoverAlertViewController.ActionType.discardChanges(OverlayPopoverActionConfiguration(leftImage: nil, rightImage: nil, title: TextConfiguration(font: UIFont.systemFont(ofSize: 12.0), color: UIColor.black), titleImageInset: 0))]
    
        config.editorConfiguration.saveButton = BanubaButtonConfiguration(
                  title: TextButtonConfiguration(
                    style: BanubaUtilities.TextConfiguration(
                      font: UIFont.systemFont(ofSize: 16.0), // Set the font size or use another UIFont method
                      color: UIColor.black // Set the color, replace with the desired UIColor
                    ),
                    text: featuresConfig.editorConfig.saveButtonText
                  ),
                  width:70,
                  height:35,
                  background: BanubaUtilities.BackgroundConfiguration(
                    cornerRadius: 18.0 ,// Set the corner radius for the button
                    color: UIColor.white // Set the background color, replace with the desired UIColor
                  )
                );

        config.applyFeatureConfig(featuresConfig)

        let lutsPath = Bundle(for: VideoEditorModule.self).bundleURL.appendingPathComponent("luts", isDirectory: true)
        config.filterConfiguration.colorEffectsURL = lutsPath

        videoEditorSDK = BanubaVideoEditor(
            token: token,
            configuration: config,
            externalViewControllerFactory: provideCustomViewFactory(featuresConfig: featuresConfig)
        )

        if videoEditorSDK == nil {
            return false
        }

        videoEditorSDK?.delegate = self
        return true
    }
    
    func provideCustomViewFactory(featuresConfig: FeaturesConfig?) -> FlutterCustomViewFactory? {
        let factory: FlutterCustomViewFactory?
        
        if featuresConfig?.audioBrowser.source == "soundstripe"{
            return nil
        }

        factory = nil
        
        return factory
    }

    func openVideoEditorDefault(
        fromViewController controller: FlutterViewController,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        
        let config = VideoEditorLaunchConfig(
            entryPoint: .camera,
            hostController: controller,
            animated: true
        )
        checkLicenseAndStartVideoEditor(with: config, flutterResult: flutterResult)
    }
    
    func openEditor(
        draftpath:String,
        fromViewController controller: FlutterViewController,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        checkLicenseAndOpenEditor(draftpath: draftpath,fromViewController: controller,flutterResult: flutterResult)
    }
    
    
    func checkLicenseAndOpenEditor( draftpath:String,fromViewController controller: FlutterViewController,flutterResult: @escaping FlutterResult) {
        if videoEditorSDK == nil {
            flutterResult(FlutterError(code: VeSdkFlutterPlugin.errSdkNotInitialized, message: VeSdkFlutterPlugin.errMessageSdkNotInitialized, details: nil))
            return
        }
        
        // Checking the license might take around 1 sec in the worst case.
        // Please optimize use if this method in your application for the best user experience
        videoEditorSDK?.getLicenseState(completion: { [weak self] isValid in
            guard let self = self else { return }
            
            if isValid {
                print("✅ The license is active")
                DispatchQueue.main.async {
                    guard let drafts = self.videoEditorSDK?.draftsService.getDrafts() else {
                        print("No drafts available")
                        self.flutterResult?([])
                        return
                    }

                    print("drafts length \(drafts.count)")

                    // Find the draft that matches the sequenceId
                    guard let draftData = drafts.first(where: { $0.sequenceId == draftpath }) else {
                        print("No draft found with the given sequenceId: \(draftpath)")
                        self.flutterResult?(nil)
                        return
                    }

                    // Open Video Editor with the preselected draft
                    let draftedConfig = VideoEditorLaunchConfig.DraftedLaunchConfig(
                        externalDraft: draftData,
                        draftsConfig: .enabled
                    )

                    let config = VideoEditorLaunchConfig(
                        entryPoint: .editor,
                        hostController: controller,
                        draftedLaunchConfig: draftedConfig,
                        animated: true
                    )

                    self.videoEditorSDK?.presentVideoEditor(
                        withLaunchConfiguration: config,
                        completion: nil
                    )
                }
            } else {
                if self.restoreLastVideoEditingSession == false {
                    self.videoEditorSDK?.clearSessionData()
                }
                self.videoEditorSDK = nil
                print("❌ Use of SDK is restricted: the license is revoked or expired")
                self.flutterResult?(FlutterError(
                    code: VeSdkFlutterPlugin.errLicenseRevoked,
                    message: VeSdkFlutterPlugin.errMessageLicenseRevoked,
                    details: nil
                ))
            }
        })

    }
    
    
    func getAllDraftsList(
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        checkLicenseAndGetAllDraftList( flutterResult: flutterResult)
    }
    
    
    func removeDraftFromList(
        draftpath:String,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        checkLicenseAndRemoveDraftFromList(draftpath: draftpath, flutterResult: flutterResult)
    }
    
    func openVideoEditorPIP(
        fromViewController controller: FlutterViewController,
        videoURL: URL,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        
        let pipLaunchConfig = VideoEditorLaunchConfig(
            entryPoint: .pip,
            hostController: controller,
            pipVideoItem: videoURL,
            musicTrack: nil,
            animated: true
        )
        
        checkLicenseAndStartVideoEditor(with: pipLaunchConfig, flutterResult: flutterResult)
    }
    
    func openVideoEditorTrimmer(
        fromViewController controller: FlutterViewController,
        videoSources: Array<URL>,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        
        let trimmerLaunchConfig = VideoEditorLaunchConfig(
            entryPoint: .trimmer,
            hostController: controller,
            videoItems: videoSources,
            musicTrack: nil,
            animated: true
        )
        
        checkLicenseAndStartVideoEditor(with: trimmerLaunchConfig, flutterResult: flutterResult)
    }
    
    
    func checkLicenseAndRemoveDraftFromList(draftpath:String, flutterResult: @escaping FlutterResult) {
        if videoEditorSDK == nil {
            flutterResult(FlutterError(code: VeSdkFlutterPlugin.errSdkNotInitialized, message: VeSdkFlutterPlugin.errMessageSdkNotInitialized, details: nil))
            return
        }
        
        // Checking the license might take around 1 sec in the worst case.
        // Please optimize use if this method in your application for the best user experience
        videoEditorSDK?.getLicenseState(completion: { [weak self] isValid in
            guard let self else { return }
            if isValid {
                print("✅ The license is active")
                
                DispatchQueue.main.async {
                    guard let drafts = self.videoEditorSDK?.draftsService.getDrafts() else {
                        print("No drafts available")
                        self.flutterResult?([])
                        return
                    }

                    // Find the draft that matches the sequenceId
                    guard let draftData = drafts.first(where: { $0.sequenceId == draftpath }) else {
                        print("No draft found with the given sequenceId: \(draftpath)")
                        self.flutterResult?(nil)
                        return
                    }
                    let isDeleted = self.videoEditorSDK?.draftsService.removeExternalDraft(draftData)
                   
            
                    print("isDeleted \(isDeleted ?? false)")
                    self.flutterResult?(isDeleted ?? false)

                   
                }
                
               

            } else {
                if self.restoreLastVideoEditingSession == false {
                    self.videoEditorSDK?.clearSessionData()
                }
                self.videoEditorSDK = nil
                print("❌ Use of SDK is restricted: the license is revoked or expired")
                flutterResult(FlutterError(code: VeSdkFlutterPlugin.errLicenseRevoked, message: VeSdkFlutterPlugin.errMessageLicenseRevoked, details: nil))
            }
        })
    }
    
    
    
    func checkLicenseAndGetAllDraftList( flutterResult: @escaping FlutterResult) {
        if videoEditorSDK == nil {
            flutterResult(FlutterError(code: VeSdkFlutterPlugin.errSdkNotInitialized, message: VeSdkFlutterPlugin.errMessageSdkNotInitialized, details: nil))
            return
        }
        
        // Checking the license might take around 1 sec in the worst case.
        // Please optimize use if this method in your application for the best user experience
        videoEditorSDK?.getLicenseState(completion: { [weak self] isValid in
            guard let self else { return }
            if isValid {
                print("✅ The license is active")
                DispatchQueue.main.async {
                    guard let drafts = self.videoEditorSDK?.draftsService.getDrafts() else {
                        print("No drafts available")
                        self.flutterResult?([])
                        return
                    }

                    let dispatchGroup = DispatchGroup() // Create a DispatchGroup
                    var draftPreviewImage: [String] = []

                    print("drafts length \(drafts.count)")

                    drafts.forEach { draft in
                        dispatchGroup.enter() // Enter the group before starting async work

                        self.videoEditorSDK?.draftsService.getPreviewForVideoSequence(
                            draft,
                            thumbnailHeight: 200,
                            completion: { preview in
                                defer { dispatchGroup.leave() } // Leave the group after async work finishes
                                
                                if let cgImage = preview?.cgImage {
                                    if let filePath = self.saveCGImageToFile(cgImage) {
                                        print("Image file path: \(filePath)")
                                        draftPreviewImage.append(filePath)
                                    } else {
                                        print("Failed to save image.")
                                    }
                                }
                            }
                        )
                    }

                    // Wait for all async tasks to complete
                    dispatchGroup.notify(queue: .main) {
                        print("All previews processed: \(draftPreviewImage)")
                        self.flutterResult?(draftPreviewImage) // Return the final result
                    }
                }

            } else {
                if self.restoreLastVideoEditingSession == false {
                    self.videoEditorSDK?.clearSessionData()
                }
                self.videoEditorSDK = nil
                print("❌ Use of SDK is restricted: the license is revoked or expired")
                flutterResult(FlutterError(code: VeSdkFlutterPlugin.errLicenseRevoked, message: VeSdkFlutterPlugin.errMessageLicenseRevoked, details: nil))
            }
        })
    }
    
    
    func saveCGImageToFile(_ cgImage: CGImage) -> String? {
        // Create a UIImage from the CGImage
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert the UIImage to PNG data
        guard let pngData = uiImage.pngData() else {
            print("Failed to convert CGImage to PNG data")
            return nil
        }
        
        // Generate a file name using the hash of the pngData
        let fileName = "\(pngData.hashValue).png"
        
        // Create a URL for the temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            // Write the PNG data to the file
            try pngData.write(to: fileURL)
            print("Image successfully saved at: \(fileURL.path)")
            return fileURL.path
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func checkLicenseAndStartVideoEditor(with config: VideoEditorLaunchConfig, flutterResult: @escaping FlutterResult) {
        if videoEditorSDK == nil {
            flutterResult(FlutterError(code: VeSdkFlutterPlugin.errSdkNotInitialized, message: VeSdkFlutterPlugin.errMessageSdkNotInitialized, details: nil))
            return
        }
        
        // Checking the license might take around 1 sec in the worst case.
        // Please optimize use if this method in your application for the best user experience
        videoEditorSDK?.getLicenseState(completion: { [weak self] isValid in
            guard let self else { return }
            if isValid {
                print("✅ The license is active")
                DispatchQueue.main.async {
                    self.videoEditorSDK?.presentVideoEditor(
                        withLaunchConfiguration: config,
                        completion: nil
                    )
                }
            } else {
                if self.restoreLastVideoEditingSession == false {
                    self.videoEditorSDK?.clearSessionData()
                }
                self.videoEditorSDK = nil
                print("❌ Use of SDK is restricted: the license is revoked or expired")
                flutterResult(FlutterError(code: VeSdkFlutterPlugin.errLicenseRevoked, message: VeSdkFlutterPlugin.errMessageLicenseRevoked, details: nil))
            }
        })
    }
}


// MARK: - Export flow
extension VideoEditorModule {
    func exportVideo(draft: BanubaVideoEditorSDK.ExternalDraft) {
        let progressView = ProgressViewController.makeViewController()
        
        progressView.cancelHandler = { [weak self] in
            self?.videoEditorSDK?.stopExport()
        }
        
        getTopViewController()?.present(progressView, animated: true)
        
        let manager = FileManager.default
        // File name
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss.SSS"
        
        let previewURL = manager.temporaryDirectory.appendingPathComponent("export_preview.png")
        
        // TODO handle multiple exported video files
        let firstFileURL = manager.temporaryDirectory.appendingPathComponent("export_\(dateFormatter.string(from: Date())).mov")
        if manager.fileExists(atPath: firstFileURL.path) {
            try? manager.removeItem(at: firstFileURL)
        }
        
        // Video configuration
        let exportVideoConfigurations: [ExportVideoConfiguration] = [
            ExportVideoConfiguration(
                fileURL: firstFileURL,
                quality: .auto,
                useHEVCCodecIfPossible: true,
                watermarkConfiguration: nil
            )
        ]
        
        // Set up export
        let exportConfiguration = ExportConfiguration(
            videoConfigurations: exportVideoConfigurations,
            isCoverEnabled: true,
            gifSettings: nil
        
        )
        
        videoEditorSDK?.export(
            using: exportConfiguration,
            exportProgress: { [weak progressView] progress in progressView?.updateProgressView(with: Float(progress)) }
        ) { [weak self] (error, coverImage) in
            // Export Callback
            DispatchQueue.main.async {
                progressView.dismiss(animated: true) {
                    // if export cancelled just hide progress view
                    if let error, error as NSError == exportCancelledError {
                        return
                    }
                    var metadataUrl: URL?
                    if let analytics = self?.videoEditorSDK?.metadata?.analyticsMetadataJSON {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_metadata.json")
                        do {
                            try analytics.write(to: url, atomically: true, encoding: .utf8)
                            metadataUrl = url
                        } catch {
                            print("Error during metadata saving: \(error)")
                        }
                    }
                    
                    // TODO 1. simplify method
                    self?.completeExport(videoUrls: [firstFileURL], metaUrl: metadataUrl, previewUrl: previewURL, error: error, previewImage: coverImage?.coverImage,draft: draft)
                }
            }
        }
    }
    
    private func completeExport(videoUrls: [URL], metaUrl: URL?, previewUrl: URL, error: Error?, previewImage: UIImage?,draft: BanubaVideoEditorSDK.ExternalDraft) {
        videoEditorSDK?.dismissVideoEditor(animated: true) {
            let success = error == nil
            if success {
                print("Video exported successfully: video sources = \(videoUrls)), meta = \(metaUrl)), preview = \(previewUrl))")
                
                let previewImageData = previewImage?.pngData()
                
                // TODO handle preview is not taken
                try? previewImageData?.write(to: previewUrl)
                
                let data = [
                    VeSdkFlutterPlugin.argExportedVideoSources: videoUrls.compactMap { $0.path },
                    VeSdkFlutterPlugin.argExportedPreview: previewUrl.path,
                    VeSdkFlutterPlugin.argExportedMeta: metaUrl?.path,
                    VeSdkFlutterPlugin.draftVideoSequence: draft.sequenceId,
                    VeSdkFlutterPlugin.musicFileName: self.videoEditorSDK?.musicMetadata?.tracks.first?.title]
                print("data \(data)")
                self.flutterResult?(data)
            } else {
                print("Error while exporting video = \(String(describing: error))")
                self.flutterResult?(FlutterError(code: VeSdkFlutterPlugin.errMissingExportResult, message: VeSdkFlutterPlugin.errMessageMissingExportResult, details: nil))
            }
            
            // Remove strong reference to video editor sdk instance
            if self.restoreLastVideoEditingSession == false {
                self.videoEditorSDK?.clearSessionData()
            }
            self.videoEditorSDK = nil
        }
    }
    
    func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
        
        var topController = keyWindow?.rootViewController
        
        while let newTopController = topController?.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
}

// MARK: - BanubaVideoEditorSDKDelegate
extension VideoEditorModule: BanubaVideoEditorDelegate {
    func videoEditorDone(_ videoEditor: BanubaVideoEditorSDK.BanubaVideoEditor) {
        
    }
    
    func videoEditorDidCancel(_ videoEditor: BanubaVideoEditor) {
        videoEditor.dismissVideoEditor(animated: true) {
            // remove strong reference to video editor sdk instance
            if self.restoreLastVideoEditingSession == false {
                self.videoEditorSDK?.clearSessionData()
            }
            self.videoEditorSDK = nil
        }
    }
    
    func videoEditor(_ videoEditor: BanubaVideoEditor, didSaveDraft draft: BanubaVideoEditorSDK.ExternalDraft) {
        exportVideo(draft: draft)
    }
}

// MARK: - Feature Config flow
extension VideoEditorConfig {
    mutating func applyFeatureConfig(_ featuresConfig: FeaturesConfig) {
        
        print("\(VideoEditorConfig.featuresConfigTag): Add Features Config with params: \(featuresConfig)")
        
        switch featuresConfig.audioBrowser.source {
            case VideoEditorConfig.featuresConfigAudioBrowserSourceSoundstripe:
                AudioBrowserConfig.shared.musicSource = .soundstripe
            case VideoEditorConfig.featuresConfigAudioBrowserSourceLocal:
                AudioBrowserConfig.shared.musicSource = .localStorageWithMyFiles
            case VideoEditorConfig.featuresConfigAudioBrowserSourceMubert:
                AudioBrowserConfig.shared.musicSource = .mubert
            default:
                AudioBrowserConfig.shared.musicSource = .allSources
        }
        
        if featuresConfig.audioBrowser.source == VideoEditorConfig.featuresConfigAudioBrowserSourceMubert {
            guard let audioBrowserParams = featuresConfig.audioBrowser.params else { return }
            guard let mubertLicence = audioBrowserParams.mubertLicence, let mubertToken = audioBrowserParams.mubertToken else { return }
            
            BanubaAudioBrowser.setMubertKeys(
                license: mubertLicence,
                token: mubertToken
            )
        }
        
        if let aiCaptions = featuresConfig.aiCaptions {
            self.captionsConfiguration.captionsUploadUrl = aiCaptions.uploadUrl
            self.captionsConfiguration.captionsTranscribeUrl = aiCaptions.transcribeUrl
            self.captionsConfiguration.apiKey = aiCaptions.apiKey
        }
            
            
//         if let aiClipping = featuresConfig.aiClipping {
//             self.autoCutConfiguration.embeddingsDownloadUrl = aiClipping.audioDataUrl
//             self.autoCutConfiguration.musicApiSelectedTracksUrl = aiClipping.audioTracksUrl
//         }

           if let aiClipping = featuresConfig.aiClipping, let audioTracksUrl = URL(string: aiClipping.audioTracksUrl) {
                    self.autoCutConfiguration.embeddingsDownloadUrl = aiClipping.audioDataUrl
//                     self.autoCutConfiguration.musicProvider =
//                         switch featuresConfig.audioBrowser.value() {
//                             case .banubaMusic:
//                                 .banubaMusic(tracksURL: audioTracksUrl)
//                             default:
//                                 .soundstripe(tracksURL: audioTracksUrl)
//                         }
                }

        self.editorConfiguration.isVideoAspectFillEnabled = featuresConfig.editorConfig.enableVideoAspectFill

//        switch featuresConfig.draftConfig.option{
//            case VideoEditorConfig.featuresConfigDraftConfigOptionAuto:
//                self.featureConfiguration.draftsConfig = .enabledSaveToDraftsByDefault
//            case VideoEditorConfig.featuresConfigDraftConfigOptionСloseOnSave:
//                self.featureConfiguration.draftsConfig = .enabledAskIfSaveNotExport
//            case VideoEditorConfig.featuresConfigDraftConfigOptionDisabled:
//                self.featureConfiguration.draftsConfig = .disabled
//            default:
//                self.featureConfiguration.draftsConfig = .enabled
//        }

        // Make customization here
        
        AudioBrowserConfig.shared.setPrimaryColor(#colorLiteral(red: 0.2350233793, green: 0.7372031212, blue: 0.7565478683, alpha: 1))
        
        var featureConfiguration = self.featureConfiguration
        featureConfiguration.supportsTrimRecordedVideo = true
        featureConfiguration.isMuteCameraAudioEnabled = true
        self.updateFeatureConfiguration(featureConfiguration: featureConfiguration)
    }
}
