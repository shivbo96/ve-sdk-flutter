import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ve_sdk_flutter/audio_meta_adapter.dart';
import 'package:ve_sdk_flutter/export_data.dart';
import 'package:ve_sdk_flutter/export_data_serializer.dart';
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
  static const String _screenAiClipping = 'aiClipping';
  static const String _getAllDraft = 'getAllDraft';
  static const String _removeDraft = 'removeDraft';
  static const String _screenEditor = 'editor';

  // Input params
  static const String _inputParamToken = 'token';
  static const String _inputParamFeaturesConfig = 'featuresConfig';
  static const String _inputParamExportData = 'exportData';
  static const String _inputParamScreen = 'screen';
  static const String _inputParamVideoSources = 'videoSources';
  static const String _inputParamDraftSequenceId = 'draftSequenceId';

  // Exported params
  static const String _exportedVideoSources = 'exportedVideoSources';
  static const String _exportedPreview = 'exportedPreview';
  static const String _exportedMeta = 'exportedMeta';
  static const String _exportedAudioMeta = 'exportedAudioMeta';
  static const String _draftSequence = 'draftVideoSequence';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_channelName);

  @override
  Future<ExportResult?> openCameraScreen(String token, FeaturesConfig featuresConfig, {ExportData? exportData}) =>
      _open(token, featuresConfig, _screenCamera, [], exportData: exportData);

  @override
  Future<ExportResult?> openPipScreen(String token, FeaturesConfig featuresConfig, String sourceVideoPath,
          {ExportData? exportData}) =>
      _open(token, featuresConfig, _screenPip, [sourceVideoPath], exportData: exportData);

  @override
  Future<ExportResult?> openTrimmerScreen(String token, FeaturesConfig featuresConfig, List<String> sourceVideoPathList,
          {ExportData? exportData}) =>
      _open(token, featuresConfig, _screenTrimmer, sourceVideoPathList, exportData: exportData);

  @override
  Future<ExportResult?> openAiClippingScreen(String token, FeaturesConfig featuresConfig, {ExportData? exportData}) =>
      _open(token, featuresConfig, _screenAiClipping, [], exportData: exportData);

  @override
  Future<List<dynamic>?> getAllDraftList(String token) => _getAllDraftList(token, _getAllDraft);

  @override
  Future<bool?> removeDraftFromList(String token, String draftSequenceId) =>
      _removeDraftFromList(token, _removeDraft, draftSequenceId);

  @override
  Future<ExportResult?> openEditorFromDraft(String token, String draftSequenceId, FeaturesConfig featuresConfig) =>
      _open(token, featuresConfig, _screenEditor, [], draftSequenceId: draftSequenceId);

  Future<List<dynamic>?> _getAllDraftList(String token, String screen) async {
    final inputParams = {
      _inputParamToken: token,
      _inputParamScreen: screen,
    };
    dynamic exportedData = await methodChannel.invokeMethod(_methodStart, inputParams);
    return exportedData;
  }

  Future<bool?> _removeDraftFromList(String token, String screen, String draftSequenceId) async {
    final inputParams = {
      _inputParamToken: token,
      _inputParamScreen: screen,
      _inputParamDraftSequenceId: draftSequenceId,
    };
    dynamic exportedData = await methodChannel.invokeMethod(_methodStart, inputParams);
    return exportedData;
  }

  Future<ExportResult?> _open(
      String token, FeaturesConfig featuresConfig, String screen, List<String> sourceVideoPathList,
      {ExportData? exportData, String draftSequenceId = ''}) async {
    if (featuresConfig.enableEditorV2 && screen == _screenTrimmer) {
      debugPrint("New UI is not available from Trimmer screen");
      return null;
    }
    final inputParams = {
      _inputParamToken: token,
      _inputParamFeaturesConfig: featuresConfig.serialize(),
      _inputParamScreen: screen,
      _inputParamVideoSources: sourceVideoPathList,
      _inputParamDraftSequenceId: draftSequenceId,
      _inputParamExportData: exportData?.serialize(),
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
      String? audioMetaJson = exportedData[_exportedAudioMeta];
      String? draftSequence = exportedData[_draftSequence];
      return ExportResult(
          videoSources: videoSources,
          previewFilePath: previewFilePath,
          metaFilePath: metaFilePath,
          draftSequence: draftSequence,
          audioMeta: AudioMetadata.parseAudioMetadata(audioMetaJson ?? ''));
    }
  }
}
