import 'package:ve_sdk_flutter/export_result.dart';
import 'package:ve_sdk_flutter/features_config.dart';

import 've_sdk_flutter_platform_interface.dart';

class VeSdkFlutter {
  Future<ExportResult?> openCameraScreen(String token, FeaturesConfig featuresConfig) =>
      VeSdkFlutterPlatform.instance.openCameraScreen(token, featuresConfig);

  Future<ExportResult?> openPipScreen(String token, FeaturesConfig featuresConfig, String sourceVideoPath) =>
      VeSdkFlutterPlatform.instance.openPipScreen(token, featuresConfig, sourceVideoPath);

  Future<ExportResult?> openTrimmerScreen(
          String token, FeaturesConfig featuresConfig, List<String> sourceVideoPathList) =>
      VeSdkFlutterPlatform.instance.openTrimmerScreen(token, featuresConfig, sourceVideoPathList);

  Future<List<dynamic>?> getAllDraftList(String token) => VeSdkFlutterPlatform.instance.getAllDraftList(token);

  Future<bool?> removeDraftFromList(String token, {required String draftPath}) =>
      VeSdkFlutterPlatform.instance.removeDraftFromList(token, draftPath);

  Future<ExportResult?> openEditorFromDraft(String token, String draftPath, FeaturesConfig featuresConfig) =>
      VeSdkFlutterPlatform.instance.openEditorFromDraft(token, draftPath, featuresConfig);
}
