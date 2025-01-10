import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ve_sdk_flutter/export_result.dart';
import 'package:ve_sdk_flutter/features_config.dart';
import 'package:ve_sdk_flutter/features_config_serializer.dart';

import 've_sdk_flutter_platform_interface.dart';

/// An implementation of [VeSdkFlutterPlatform] that uses method channels.
class MethodChannelVeSdkFlutter extends VeSdkFlutterPlatform {
  // Channel and method
  static const String _channelName = 've_sdk_flutter';
  static const String _methodStart = 'startVideoEditor';

  // Screens
  static const String _screenCamera = 'camera';
  static const String _screenPip = 'pip';
  static const String _screenTrimmer = 'trimmer';
  static const String _getAllDraft = 'getAllDraft';
  static const String _removeDraft = 'removeDraft';
  static const String _screenEditor = 'editor';
  static const String _exportExternalDraft = "exportExternalDraft";
  static const String _importExternalDraft = "importExternalDraft";

  // Input params
  static const String _inputParamToken = 'token';
  static const String _inputParamFeaturesConfig = 'featuresConfig';
  static const String _inputParamScreen = 'screen';
  static const String _inputParamVideoSources = 'videoSources';
  static const String _inputParamDraftIndex = 'draftIndex';
  static const String _inputParamDraftPath = 'draftPath';
  static const String _inputParamExternalDraftUrl = 'externalDraftUrl';

  // Exported params
  static const String _exportedVideoSources = 'exportedVideoSources';
  static const String _exportedPreview = 'exportedPreview';
  static const String _exportedMeta = 'exportedMeta';
  static const String _musicFileName = 'musicFileName';
  static const String _draftSequence = 'draftVideoSequence';

  /// The method channel used to interact with the native platform.
  // @visibleForTesting
  final methodChannel = const MethodChannel(_channelName);

  @override
  Future<ExportResult?> openCameraScreen(String token, FeaturesConfig featuresConfig) =>
      _open(token, featuresConfig, _screenCamera, []);

  @override
  Future<ExportResult?> openPipScreen(String token, FeaturesConfig featuresConfig, String sourceVideoPath) =>
      _open(token, featuresConfig, _screenPip, [sourceVideoPath]);

  @override
  Future<ExportResult?> openTrimmerScreen(
          String token, FeaturesConfig featuresConfig, List<String> sourceVideoPathList) =>
      _open(token, featuresConfig, _screenTrimmer, sourceVideoPathList);

  @override
  Future<List<dynamic>?> getAllDraftList(String token) => _getAllDraftList(token, _getAllDraft);

  @override
  Future<bool?> removeDraftFromList(String token, String draftPath) =>
      _removeDraftFromList(token, _removeDraft, draftPath);

  @override
  Future<ExportResult?> openEditorFromDraft(String token, String draftPath, FeaturesConfig featuresConfig) =>
      _open(token, featuresConfig, _screenEditor, [], draftPath: draftPath);

  Future<List<dynamic>?> _getAllDraftList(String token, String screen) async {
    final inputParams = {
      _inputParamToken: token,
      _inputParamScreen: screen,
    };
    dynamic exportedData = await methodChannel.invokeMethod(_methodStart, inputParams);
    return exportedData;
  }

  Future<bool?> _removeDraftFromList(String token, String screen, String draftPath) async {
    final inputParams = {
      _inputParamToken: token,
      _inputParamScreen: screen,
      _inputParamDraftPath: draftPath,
    };
    dynamic exportedData = await methodChannel.invokeMethod(_methodStart, inputParams);
    return exportedData;
  }

  Future<ExportResult?> _open(
      String token, FeaturesConfig featuresConfig, String screen, List<String> sourceVideoPathList,
      {int draftIndex = 0, String externalDraftUrl = '', String draftPath = ''}) async {
    final inputParams = {
      _inputParamToken: token,
      _inputParamFeaturesConfig: featuresConfig.serialize(),
      _inputParamScreen: screen,
      _inputParamVideoSources: sourceVideoPathList,
      _inputParamDraftIndex: draftIndex,
      _inputParamDraftPath: draftPath,
      _inputParamExternalDraftUrl: externalDraftUrl
    };

    debugPrint('Start video editor with params = $inputParams');

    dynamic exportedData = await methodChannel.invokeMethod(_methodStart, inputParams);

    if (exportedData == null) {
      return null;
    } else {
      List<Object?> sources = exportedData[_exportedVideoSources] as List<Object?>;
      List<String> videoSources = sources.where((element) => element != null).map((e) => e.toString()).toList();

      String? metaFilePath = exportedData[_exportedMeta];
      String? previewFilePath = exportedData[_exportedPreview];
      String? musicFileName = exportedData[_musicFileName];
      String? draftSequence = exportedData[_draftSequence];
      return ExportResult(
          videoSources: videoSources,
          previewFilePath: previewFilePath,
          musicFileName: musicFileName,
          draftSequence: draftSequence,
          metaFilePath: metaFilePath);
    }
  }
}
