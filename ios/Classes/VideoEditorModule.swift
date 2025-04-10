//
//  VideoEditorModule.swift
//  ve_sdk_flutter
//
//  Created by Gleb Prischepa on 5/4/24.
//

import Foundation
import BanubaVideoEditorSDK
import BanubaAudioBrowserSDK
import BanubaVideoEditorCore
import Flutter

protocol VideoEditor {
    func initVideoEditor(token: String, featuresConfig: FeaturesConfig, exportData: ExportData) -> Bool
    
    func openVideoEditorDefault(fromViewController controller: FlutterViewController, flutterResult: @escaping FlutterResult)
    
    func openVideoEditorPIP(fromViewController controller: FlutterViewController, videoURL: URL, flutterResult: @escaping FlutterResult)
    
    func openVideoEditorTrimmer(fromViewController controller: FlutterViewController, videoSources: Array<URL>, flutterResult: @escaping FlutterResult)

    func getAllDraftsList(flutterResult: @escaping FlutterResult)

    func removeDraftFromList(draftSequenceId:String,flutterResult: @escaping FlutterResult)

    func openEditor(draftSequenceId:String,fromViewController controller: FlutterViewController,flutterResult: @escaping FlutterResult)

}

class VideoEditorModule: VideoEditor {
    
    private var videoEditorSDK: BanubaVideoEditor?
    private var flutterResult: FlutterResult?
    private var currentController: FlutterViewController?
    private var exportData: ExportData?
    private var featuresConfig: FeaturesConfig?

    // Use “true” if you want users could restore the last video editing session.
    private let restoreLastVideoEditingSession: Bool = false

    func initVideoEditor(token: String, featuresConfig: FeaturesConfig, exportData: ExportData) -> Bool {
        guard videoEditorSDK == nil else {
            debugPrint("Video Editor SDK is already initialized")
            return true
        }
        
        var config = VideoEditorConfig()

        self.featuresConfig = featuresConfig

        config.applyFeatureConfig(featuresConfig)

        let lutsPath = Bundle(for: VideoEditorModule.self).bundleURL.appendingPathComponent("luts", isDirectory: true)
        config.filterConfiguration.colorEffectsURL = lutsPath

        videoEditorSDK = BanubaVideoEditor(
            token: token,
            arguments: [.useEditorV2 : featuresConfig.enableEditorV2],
            configuration: config,
            externalViewControllerFactory: provideCustomViewFactory(featuresConfig: featuresConfig)
        )

        if videoEditorSDK == nil {
            return false
        }

        self.exportData = exportData

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
        self.currentController = controller
        self.flutterResult = flutterResult
        
        let config = VideoEditorLaunchConfig(
            entryPoint: .camera,
            hostController: controller,
            animated: true
        )
        checkLicenseAndStartVideoEditor(with: config, flutterResult: flutterResult)
    }
    
    func getAllDraftsList(
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        checkLicenseAndGetAllDraftList( flutterResult: flutterResult)
    }
    
    
    func removeDraftFromList(
        draftSequenceId:String,
        flutterResult: @escaping FlutterResult
    ) {
        self.flutterResult = flutterResult
        checkLicenseAndRemoveDraftFromList(draftSequenceId: draftSequenceId, flutterResult: flutterResult)
    }
    
    func openEditor(
            draftSequenceId:String,
            fromViewController controller: FlutterViewController,
            flutterResult: @escaping FlutterResult
        ) {
            self.flutterResult = flutterResult
            checkLicenseAndOpenEditor(draftSequenceId: draftSequenceId,fromViewController: controller,flutterResult: flutterResult)
        }
    
    func checkLicenseAndOpenEditor( draftSequenceId:String,fromViewController controller: FlutterViewController,flutterResult: @escaping FlutterResult) {
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
                       guard let draftData = drafts.first(where: { $0.sequenceId == draftSequenceId }) else {
                           print("No draft found with the given sequenceId: \(draftSequenceId)")
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
    
        

    
    func checkLicenseAndRemoveDraftFromList(draftSequenceId:String, flutterResult: @escaping FlutterResult) {
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
                       guard let draftData = drafts.first(where: { $0.sequenceId == draftSequenceId }) else {
                           print("No draft found with the given sequenceId: \(draftSequenceId)")
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
    
    
    func openVideoEditorPIP(
        fromViewController controller: FlutterViewController,
        videoURL: URL,
        flutterResult: @escaping FlutterResult
    ) {
        self.currentController = controller
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
        self.currentController = controller
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

    func openVideoEditorAiClipping(
        fromViewController controller: FlutterViewController,
        flutterResult: @escaping FlutterResult
    ) {
        self.currentController = controller
        self.flutterResult = flutterResult

        let config = VideoEditorLaunchConfig(
            entryPoint: .aiClipping,
            hostController: controller,
            animated: true
        )
        checkLicenseAndStartVideoEditor(with: config, flutterResult: flutterResult)
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
    func exportVideo(draft: BanubaVideoEditorSDK.ExternalDraft?) {
        
        guard let exportData, let currentController else {
            print("❌ Export Config is not set")
            return
        }
        
        let progressView = createProgressViewController()
        
        progressView.cancelHandler = { [weak self] in
            self?.videoEditorSDK?.stopExport()
        }
        
        getTopViewController()?.present(progressView, animated: true)
        
        debugPrint("Add Export Param with params: \(exportData)")
        
        let watermarkConfiguration = exportData.watermark?.watermarkConfigurationValue(controller: currentController)
        
        let exportProvider = ExportProvider(exportData: exportData, watermarkConfiguration: watermarkConfiguration)
                
        videoEditorSDK?.export(
            using: exportProvider.provideExportConfiguration(),
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

                    var audioMetaJSON: String?
                    if let jsonData = try? JSONEncoder().encode(self?.videoEditorSDK?.musicMetadata?.tracks),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        audioMetaJSON = jsonString.replacingOccurrences(of: "\\/", with: "/")
                    }

                    // TODO 1. simplify method
                    self?.completeExport(
                        videoUrls: Array(exportProvider.fileUrls.values),
                        metaUrl: metadataUrl,
                        audioMetaJSON: audioMetaJSON,
                        previewUrl: FileManager.default.temporaryDirectory.appendingPathComponent("export_preview.png"),
                        error: error,
                        previewImage: coverImage?.coverImage,
                        draft: draft
                    )
                }
            }
        }
    }
    
    private func completeExport(
        videoUrls: [URL],
        metaUrl: URL?,
        audioMetaJSON: String?,
        previewUrl: URL,
        error: Error?,
        previewImage: UIImage?,
        draft: BanubaVideoEditorSDK.ExternalDraft?
    ) {
        videoEditorSDK?.dismissVideoEditor(animated: true) {
            let success = error == nil
            if success {
                print(
                    "Video exported successfully: video sources = \(videoUrls)), meta = \(String(describing: metaUrl))), audio metadata = \(String(describing: audioMetaJSON)) preview = \(previewUrl) draft = \(draft?.sequenceId ?? "nil"))"
                )
                
                let previewImageData = previewImage?.pngData()
                
                // TODO handle preview is not taken
                try? previewImageData?.write(to: previewUrl)
                
                let data = [
                    VeSdkFlutterPlugin.argExportedVideoSources: videoUrls.compactMap { $0.path },
                    VeSdkFlutterPlugin.argExportedPreview: previewUrl.path,
                    VeSdkFlutterPlugin.argExportedMeta: metaUrl?.path,
                    VeSdkFlutterPlugin.draftVideoSequence: draft?.sequenceId,
                    VeSdkFlutterPlugin.argExportedAudioMeta: audioMetaJSON
                ]
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
    
    func createProgressViewController() -> ProgressViewController {
        let progressViewController = ProgressViewController.makeViewController()
        progressViewController.message = NSLocalizedString("com.banuba.alert.progressView.exportingVideo", comment: "")
        return progressViewController
    }
}

// MARK: - BanubaVideoEditorSDKDelegate
extension VideoEditorModule: BanubaVideoEditorDelegate {
    
    func videoEditorDidCancel(_ videoEditor: BanubaVideoEditor) {
        videoEditor.dismissVideoEditor(animated: true) {
            // remove strong reference to video editor sdk instance
            if self.restoreLastVideoEditingSession == false {
                self.videoEditorSDK?.clearSessionData()
            }
            self.videoEditorSDK = nil
        }
    }
    
    func videoEditorDone(_ videoEditor: BanubaVideoEditorSDK.BanubaVideoEditor) {
           print("videoEditor: \(videoEditor.draftActionType.isSaveOrUpdate)")
           if(videoEditor.draftActionType.isSaveOrUpdate == false){
               exportVideo(draft: nil)
           }
          
       }
//    
    func videoEditor(_ videoEditor: BanubaVideoEditor, didSaveDraft draft: BanubaVideoEditorSDK.ExternalDraft) {
           exportVideo(draft: draft)
       }
    

    func videoEditors(_ videoEditor: BanubaVideoEditor, didSaveDraft draft: BanubaVideoEditorSDK.ExternalDraft,shouldProcessMediaUrls urls: [URL]) -> Bool {
        guard let featuresConfig else {
            return true
        }
        if featuresConfig.processPictureExternally {
            guard let jpegURL = urls.first(where: { $0.pathExtension.lowercased() == "jpeg" }),
                  let imageData = try? Data(contentsOf: jpegURL),
                  !imageData.isEmpty,
                  let resultImage = UIImage(data: imageData) else {
                return true
            }

            videoEditor.dismissVideoEditor(animated: true) {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    // Calling clearSessionData() also removes any files stored in urls array
                    self.videoEditorSDK?.clearSessionData()

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss.SSS"

                    self.completeExport(
                        videoUrls: [],
                        metaUrl: nil,
                        audioMetaJSON: nil,
                        previewUrl: FileManager.default.temporaryDirectory.appendingPathComponent("\(dateFormatter.string(from: Date())).png"),
                        error: nil,
                        previewImage: resultImage,
                        draft: draft
                        
                    )
                }
            }
            return false
        } else {
            return true
        }
    }
}

// MARK: - Feature Config flow
extension VideoEditorConfig {
    mutating func applyFeatureConfig(_ featuresConfig: FeaturesConfig) {
        
        print("Add Features Config with params: \(featuresConfig)")
        
        if featuresConfig.audioBrowser.source != VideoEditorConfig.featuresConfigAudioBrowserSourceDisabled {
            AudioBrowserConfig.shared.musicSource = featuresConfig.audioBrowser.value()
        } else {
            applyDisabledMusicConfig()
        }

        if featuresConfig.audioBrowser.source == VideoEditorConfig.featuresConfigAudioBrowserSourceMubert {
            addMubertParams(featuresConfig)
        }
        
        if featuresConfig.enableEditorV2 {
            self.combinedGalleryConfiguration.visibleTabsInGallery = [GalleryMediaType.video, GalleryMediaType.photo]
        }
        
        if let aiCaptions = featuresConfig.aiCaptions {
            self.captionsConfiguration.captionsUploadUrl = aiCaptions.uploadUrl
            self.captionsConfiguration.captionsTranscribeUrl = aiCaptions.transcribeUrl
            self.captionsConfiguration.apiKey = aiCaptions.apiKey
        }
            
            
        if let aiClipping = featuresConfig.aiClipping, let audioTracksUrl = URL(string: aiClipping.audioTracksUrl) {
            self.aiClippingConfiguration.embeddingsDownloadUrl = aiClipping.audioDataUrl
            self.aiClippingConfiguration.musicProvider =
                switch featuresConfig.audioBrowser.value() {
                    case .banubaMusic:
                        .banubaMusic(tracksURL: audioTracksUrl)
                    default:
                        .soundstripe(tracksURL: audioTracksUrl)
                }
        }
        
        self.editorConfiguration.isVideoAspectFillEnabled = featuresConfig.editorConfig.enableVideoAspectFill
        
        self.featureConfiguration.draftsConfig = featuresConfig.draftsConfig.value()
        
        if let gifPickerConfig = featuresConfig.gifPickerConfig {
            self.gifPickerConfiguration.giphyAPIKey = gifPickerConfig.giphyApiKey
        }

        self.videoDurationConfiguration = featuresConfig.videoDurationConfig.value()

        self.featureConfiguration.isVideoCoverSelectionEnabled = featuresConfig.editorConfig.enableVideoCover
        self.featureConfiguration.isAspectsEnabled = false
        self.featureConfiguration.isDraftSavedToastEnabled = false
        self.videoEditorViewConfiguration.primaryAspectRatio = .aspect9x16


        self.recorderConfiguration.previewScalingMode = .aspectFill
        self.editorConfiguration.saveButton = BanubaButtonConfiguration(
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
        // Make customization here
        
        AudioBrowserConfig.shared.setPrimaryColor(#colorLiteral(red: 0.2350233793, green: 0.7372031212, blue: 0.7565478683, alpha: 1))
        
        var featureConfiguration = self.featureConfiguration
        featureConfiguration.supportsTrimRecordedVideo = true
        featureConfiguration.isMuteCameraAudioEnabled = true
        self.updateFeatureConfiguration(featureConfiguration: featureConfiguration)
    }
    
    private func addMubertParams(_ featuresConfig: FeaturesConfig){
        guard let audioBrowserParams = featuresConfig.audioBrowser.params else { return }
        guard let mubertLicence = audioBrowserParams.mubertLicence, let mubertToken = audioBrowserParams.mubertToken else { return }
    
        BanubaAudioBrowser.setMubertKeys(
            license: mubertLicence,
            token: mubertToken
        )
    }
    
    private mutating func applyDisabledMusicConfig(){
        self.recorderConfiguration.additionalEffectsButtons = self.recorderConfiguration.additionalEffectsButtons.filter{$0.identifier != .sound}
        self.musicEditorConfiguration.mainMusicViewControllerConfig.editButtons = self.musicEditorConfiguration.mainMusicViewControllerConfig.editButtons
            .filter({$0.type != .track})
        self.videoEditorViewConfiguration.timelineConfiguration.isAddAudioEnabled = false
    }
}
