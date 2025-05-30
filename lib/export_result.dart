import 'package:ve_sdk_flutter/audio_meta_adapter.dart';

/// Represents data exported with Video Editor SDK. Contains a number of exported video files,
/// preview file and meta.
class ExportResult {
  List<String> videoSources;
  String? previewFilePath;
  String? metaFilePath;
  List<AudioMetadata>? audioMeta;
  String? draftSequence;

  ExportResult(
      {required this.videoSources,
      required this.previewFilePath,
      required this.metaFilePath,
      required this.audioMeta,
      required this.draftSequence});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResult &&
          runtimeType == other.runtimeType &&
          videoSources == other.videoSources &&
          previewFilePath == other.previewFilePath &&
          metaFilePath == other.metaFilePath &&
          draftSequence == other.draftSequence &&
          audioMeta == other.audioMeta;

  @override
  int get hashCode =>
      videoSources.hashCode ^
      previewFilePath.hashCode ^
      metaFilePath.hashCode ^
      audioMeta.hashCode ^
      draftSequence.hashCode;

  @override
  String toString() {
    return 'ExportResult{videoSources: $videoSources, previewFilePath: $previewFilePath, metaFilePath: $metaFilePath, audioMeta: $audioMeta, draftSequence: $draftSequence}';
  }
}
